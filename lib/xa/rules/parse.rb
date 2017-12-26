require 'parslet'

module XA
  module Rules
    module Parse
      class ActionParser < Parslet::Parser
        rule(:nl)                 { str('\n') }
        rule(:space)              { match('\s').repeat(1) }
        rule(:quote)              { str("'") }
        rule(:string)             { quote >> match('\w').repeat(1) >> quote }
        rule(:number)             { match('[0-9]').repeat(1) }
        rule(:semi)               { str(';') }
        rule(:comma)              { str(',') }
        rule(:colon)              { str(':') }
        rule(:dot)                { str('.') }
        rule(:eq)                 { str('=') }
        rule(:at)                 { str('@') }
        rule(:lparen)             { str('(') }
        rule(:rparen)             { str(')') }
        rule(:lsquare)            { str('[') }
        rule(:rsquare)            { str(']') }

        rule(:name)               { match('\w').repeat(1) }
        rule(:key_name)           { match('\w').repeat(1) >> (str('.') >> match('\w').repeat(1)).repeat }
        rule(:value)              { string.as(:string) | number.as(:number) }

        rule(:kw_when)            { match('[wW]') >> match('[hH]') >> match('[eE]') >> match('[nN]') }
        rule(:kw_assemble)        { match('[aA]') >> match('[sS]') >> match('[sS]') >> match('[eE]') >> match('[mM]') >> match('[bB]') >> match('[lL]') >> match('[eE]') }
        rule(:kw_column)          { match('[cC]') >> match('[oO]') >> match('[lL]') >> match('[uU]') >> match('[mM]') >> match('[nN]') }
        rule(:kw_from)            { match('[fF]') >> match('[rR]') >> match('[oO]') >> match('[mM]') }
        rule(:kw_map)             { match('[mM]') >> match('[aA]') >> match('[pP]') }
        rule(:kw_using)           { match('[uU]') >> match('[sS]') >> match('[iI]') >> match('[nN]') >> match('[gG]') }
        rule(:kw_require)         { match('[rR]') >> match('[eE]') >> match('[qQ]') >> match('[uU]') >> match('[iI]') >> match('[rR]') >> match('[eE]') }
        rule(:kw_revise)          { match('[rR]') >> match('[eE]') >> match('[vV]') >> match('[iI]') >> match('[sS]') >> match('[eE]') }
        rule(:kw_index)           { match('[iI]') >> match('[nN]') >> match('[dD]') >> match('[eE]') >> match('[xX]') }
        rule(:kw_as)              { match('[aA]') >> match('[sS]') }
        rule(:kw_keep)            { match('[kK]') >> match('[eE]') >> match('[eE]') >> match('[pP]') }

        rule(:op_gte)             { str('>=') }
        rule(:op_lte)             { str('<=') }
        rule(:op_eq)              { str('==') }
        rule(:op_gt)              { str('>') }
        rule(:op_lt)              { str('<') }

        # TODO: remove (it's context_reference)
        rule(:column_reference)   { at >> key_name.as(:name) }
        rule(:section_reference)  { name.as(:section) >> colon >> key_name.as(:key) }
        rule(:context_reference)  { at >> key_name.as(:key) }
        rule(:reference)          { section_reference.as(:section) | context_reference.as(:context) } 
        rule(:op)                 { op_lte | op_gte | op_eq | op_lt | op_gt }
        rule(:operand)            { value.as(:value) | reference.as(:reference) | name.as(:name) }
        rule(:expr)               { operand.as(:left) >> space.maybe >> op.as(:op) >> space.maybe >> operand.as(:right) }
        
        rule(:when_statement)     { kw_when >> space >> expr.as(:expr) }

        rule(:require_indexes)    { kw_index >> space >> lsquare >> name.as(:column) >> (comma >> space.maybe >> name.as(:column)).repeat >> rsquare } 
        rule(:require_statement)  { kw_require >> space >> name.as(:id) >> (space >> require_indexes.as(:indexes)).maybe >> (space >> kw_as >> space >> name.as(:name)).maybe }

        rule(:assemble_column)    { kw_column >> space >> name.as(:source) >> (space >> kw_as >> space >> name.as(:name)).maybe >> space >> kw_from >> space >> name.as(:table_name) >> space >> kw_when >> space >> expr.as(:expr) }
        rule(:assemble_columns)   { assemble_column >> (space >> assemble_column).repeat }
        rule(:assemble_statement) { kw_assemble >> space >> name.as(:table_name) >> space >> assemble_columns.as(:columns) }

        rule(:keep_statement)     { kw_keep >> space >> name.as(:table_name) }
        
        rule(:function_ref)       { name.as(:name) >> (lparen >> assign_expr >> (space.maybe >> comma >> space.maybe >> assign_expr).repeat >> rparen).as(:args) }
        rule(:assign_expr)        { function_ref.as(:func_ref) | column_reference.as(:col_ref) | value.as(:value) | key_name.as(:key) }
        rule(:map_assignment)     { kw_using >> space >> name.as(:name) >> space.maybe >> eq >> space.maybe >> assign_expr.as(:expr) }
        rule(:map_assignments)    { map_assignment >> (space >> map_assignment).repeat }
        rule(:map_statement)      { kw_map >> space >> reference.as(:table_ref) >> space >> map_assignments.as(:assignments) }

        rule(:revise_assignment)  { kw_using >> space >> column_reference.as(:column) >> space.maybe >> eq >> space.maybe >> assign_expr.as(:expr) }
        rule(:revise_assignments) { revise_assignment >> (space >> revise_assignment).repeat }
        rule(:revise_statement)   { kw_revise >> space >> reference.as(:table_ref) >> space >> revise_assignments.as(:assignments) }
        
        rule(:statement)          { (when_statement.as(:when) | require_statement.as(:require) | assemble_statement.as(:assemble) | keep_statement.as(:keep) | map_statement.as(:map) | revise_statement.as(:revise)) >> semi }
        rule(:statements)         { statement >> (space >> statement).repeat }
        
        root(:statements)
      end

      def maybe_convert_value(v)
        cv = [
          [/^'(\w+)'$/, :to_s],
          [/^([0-9]+)$/, :to_s],
        ].map do |re|
          m = re[0].match(v)
          m ? m[1].send(re[1]) : nil
        end.compact.first

        cv || v
      end

      OPS = {
        '==' => 'eq',
        '>'  => 'gt',
        '<'  => 'lt',
        '>=' => 'gte',
        '<=' => 'lte',
      }

      def build_reference_operand(opr)
        t = opr.keys.first
        case t
        when :section
          rv = { 'section' => opr[t][:section].to_s, 'key' => opr[t][:key].to_s }
        when :context
          rv = { 'section' => '_context', 'key' => opr[t][:key].to_s }
        end

        rv.merge('type' => 'reference')
      end
      
      def build_operand(opr)
        t = opr.keys.first
        case t
        when :reference
          build_reference_operand(opr[t])
        when :key
          { 'type' => 'key', 'value' => opr[t].to_s }
        when :name
          { 'type' => 'name', 'value' => opr[t].to_s }
        when :value
          vt = opr[t].keys.first
          case vt
          when :string
            { 'type' => 'string', 'value' => maybe_convert_value(opr[t][vt].to_s) }
          when :number
            { 'type' => 'number', 'value' => maybe_convert_value(opr[t][vt].to_s) }
          end
        else
          { 'type' => 'unk' }
        end
      end
      
      def build_expr_tree(expr)
        {
          'left'  => build_operand(expr[:left]),
          'right' => build_operand(expr[:right]),
          'op'    => OPS.fetch(expr[:op].to_s, 'unk'),
        }
      end
      
      def build_assemble_tree(stm)
        cols = stm[:columns]
        cols = [cols] if cols.class == Hash
        {
          'table_name' => stm[:table_name].to_s,
          'columns'    => cols.map do |col|
            source = col[:source].to_s
            {
              table: col[:table_name].to_s,
              col: {
                'name'       => col.fetch(:name, source).to_s,
                'source'     => source,
                'expr'       => build_expr_tree(col[:expr]),
              }
            }
          end.inject({}) do |o, col|
            table_name = col[:table]
            table_cols = o.fetch(table_name, [])
            o.merge(table_name => table_cols + [col[:col]])
          end,
        }
      end

      def build_keep_tree(stm)
        { 'table_name' => stm[:table_name].to_s }
      end

      def build_assignment_expr(expr)
        at = expr.keys.first
        case at
        when :col_ref
          { "type" => "column", "value" => expr[at][:name].to_s }
        when :func_ref
          {
            "type" => "function",
            "name" => expr[at][:name].to_s,
            "args" => expr[at][:args].map(&method(:build_assignment_expr)),
          }
        else
          build_operand(expr)
        end
      end
      
      def build_map_tree(stm)
        assigns = stm[:assignments]
        assigns = [assigns] if assigns.class == Hash
        {
          'table_ref'   => stm[:table_ref].to_s,
          'assignments' => assigns.inject({}) do |o, a|
            o.merge(a[:name].to_s => build_assignment_expr(a[:expr]))
          end
        }
      end
      
      def build_revise_tree(stm)
        assigns = stm[:assignments]
        assigns = [assigns] if assigns.class == Hash
        {
          'table_ref'   => stm[:table_ref].to_s,
          'assignments' => assigns.inject({}) do |o, a|
            o.merge(a[:column][:name].to_s => build_assignment_expr(a[:expr]))
          end
        }
      end

      def build_when_tree(stm)
        {
          'expr' => build_expr_tree(stm[:expr]),
        }
      end

      def parse(content)
        p content
        tree = ActionParser.new.parse(content)
        tree = [tree] if tree.class == Hash

        tree.inject({}) do |o, stms|
          t = stms.keys.first
          stm = stms[t]

          case t
          when :when
            expr = build_when_tree(stm)
            whens = o.fetch('whens', {})
            section = expr['expr']['left']['section']
            o.merge('whens' => whens.merge(section => whens.fetch(section, []) + [expr]))
          when :require
            id = stm[:id].to_s
            name = stm.fetch(:name, id).to_s
            indexes = stm.fetch(:indexes, []).map { |col| col[:column].to_s }
            requires = o.fetch('requires', [])
            o.merge('requires' => requires + [{ 'id' => id, 'name' => name, 'indexes' => indexes }])
          when :assemble
            o.merge('steps' => o.fetch('steps', []) + [build_assemble_tree(stm).merge('name' => 'assemble')])
          when :keep
            o.merge('steps' => o.fetch('steps', []) + [build_keep_tree(stm).merge('name' => 'keep')])
          when :map
            o.merge('steps' => o.fetch('steps', []) + [build_map_tree(stm).merge('name' => 'map')])
          when :revise
            o.merge('steps' => o.fetch('steps', []) + [build_revise_tree(stm).merge('name' => 'revise')])
          end
        end
      end
    end
  end
end
