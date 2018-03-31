require 'parslet'

module XA
  module Rules
    module Parse
      class ActionParser < Parslet::Parser
        rule(:nl)                 { str('\n') }
        rule(:space)              { match('\s').repeat(1) }
        rule(:quote)              { str("'") }
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
        rule(:dollar)             { str('$') }

        rule(:kw_when)            { match('[wW]') >> match('[hH]') >> match('[eE]') >> match('[nN]') }
        rule(:kw_assemble)        { match('[aA]') >> match('[sS]') >> match('[sS]') >> match('[eE]') >> match('[mM]') >> match('[bB]') >> match('[lL]') >> match('[eE]') }
        rule(:kw_column)          { match('[cC]') >> match('[oO]') >> match('[lL]') >> match('[uU]') >> match('[mM]') >> match('[nN]') }
        rule(:kw_columns)         { match('[cC]') >> match('[oO]') >> match('[lL]') >> match('[uU]') >> match('[mM]') >> match('[nN]') >> match('[sS]') }
        rule(:kw_from)            { match('[fF]') >> match('[rR]') >> match('[oO]') >> match('[mM]') }
        rule(:kw_map)             { match('[mM]') >> match('[aA]') >> match('[pP]') }
        rule(:kw_using)           { match('[uU]') >> match('[sS]') >> match('[iI]') >> match('[nN]') >> match('[gG]') }
        rule(:kw_require)         { match('[rR]') >> match('[eE]') >> match('[qQ]') >> match('[uU]') >> match('[iI]') >> match('[rR]') >> match('[eE]') }
        rule(:kw_revise)          { match('[rR]') >> match('[eE]') >> match('[vV]') >> match('[iI]') >> match('[sS]') >> match('[eE]') }
        rule(:kw_index)           { match('[iI]') >> match('[nN]') >> match('[dD]') >> match('[eE]') >> match('[xX]') }
        rule(:kw_as)              { match('[aA]') >> match('[sS]') }
        rule(:kw_keep)            { match('[kK]') >> match('[eE]') >> match('[eE]') >> match('[pP]') }
        rule(:kw_filter)          { match('[fF]') >> match('[iI]') >> match('[lL]') >> match('[tT]') >> match('[eE]') >> match('[rR]') }

        rule(:op_gte)             { str('>=') }
        rule(:op_lte)             { str('<=') }
        rule(:op_eq)              { str('==') }
        rule(:op_gt)              { str('>') }
        rule(:op_lt)              { str('<') }

        rule(:string)             { quote >> match('\w').repeat(1) >> quote }
        rule(:number)             { match('[0-9]').repeat(1) }
        rule(:name)               { match('[a-zA-Z]') >> match('\w').repeat }
        rule(:name_list)          { name.as(:name) >> (comma >> space.maybe >> name.as(:name)).repeat }
        rule(:key_name)           { name >> (str('.') >> name).repeat }
        rule(:version)            { number >> dot >> number >> dot >> number }
        rule(:value)              { string.as(:string) | number.as(:number) }

        rule(:section_reference)  { name.as(:section) >> colon >> key_name.as(:key) }
        rule(:context_reference)  { at >> key_name.as(:key) }
        rule(:local_reference)    { key_name.as(:key) }
        rule(:vtable_reference)   { dollar }
        rule(:table_reference)    { section_reference.as(:section) | context_reference.as(:context) | vtable_reference.as(:virtual) }
        rule(:function_reference) { name.as(:name) >> (lparen >> assign_expr >> (space.maybe >> comma >> space.maybe >> assign_expr).repeat >> rparen).as(:args) }
        rule(:reference)          { section_reference.as(:section) | context_reference.as(:context) | local_reference.as(:local) } 
        rule(:operand)            { value.as(:value) | reference.as(:reference) }
        rule(:op)                 { op_lte | op_gte | op_eq | op_lt | op_gt }
        rule(:expr)               { operand.as(:left) >> space.maybe >> op.as(:op) >> space.maybe >> operand.as(:right) }
        
        rule(:when_statement)     { kw_when >> space >> expr.as(:expr) }
        rule(:when_statements)    { when_statement >> (space >> when_statement).repeat }

        rule(:require_indexes)    { kw_index >> space >> lsquare >> name.as(:column) >> (comma >> space.maybe >> name.as(:column)).repeat >> rsquare }
        rule(:require_reference)  { key_name.as(:package) >> colon >> name.as(:id) >> colon >> version.as(:version) }
        rule(:require_statement)  { kw_require >> space >> require_reference.as(:reference) >> (space >> require_indexes.as(:indexes)).maybe >> (space >> kw_as >> space >> name.as(:name)).maybe }

        rule(:assemble_column)    { kw_column >> space >> name.as(:source) >> (space >> kw_as >> space >> name.as(:name)).maybe >> space >> kw_from >> space >> reference.as(:reference) >> space >> kw_when >> space >> expr.as(:expr) }
        rule(:assemble_column_import) { kw_columns >> space >> (lparen >> name_list.as(:column_names) >> rparen >> space).maybe >> kw_from >> space >> reference.as(:reference) }
        rule(:assemble_columnset) { assemble_column.as(:column) | assemble_column_import.as(:column_import) } 
        rule(:assemble_columns)   { assemble_columnset >> (space >> assemble_columnset).repeat }
        rule(:assemble_statement) { kw_assemble >> space >> name.as(:table_name) >> space >> assemble_columns.as(:columns) }

        rule(:keep_statement)     { kw_keep >> space >> name.as(:table_name) }
        
        rule(:assign_expr)        { function_reference.as(:function) | reference | value.as(:value) }
        rule(:assignment)         { kw_using >> space >> name.as(:name) >> space.maybe >> eq >> space.maybe >> assign_expr.as(:expr) }
        rule(:assignments)        { assignment >> (space >> assignment).repeat }
        rule(:assign_statement)   { table_reference.as(:table) >> space >> assignments.as(:assignments) }
        rule(:map_statement)      { kw_map >> space >> assign_statement }
        rule(:revise_statement)   { kw_revise >> space >> assign_statement }

        rule(:filter_statement)   { kw_filter >> space >> table_reference.as(:table) >> space >> when_statements.as(:whens) }
        
        rule(:statement)          { (when_statement.as(:when) | require_statement.as(:require) | assemble_statement.as(:assemble) | keep_statement.as(:keep) | map_statement.as(:map) | revise_statement.as(:revise) | filter_statement.as(:filter)) >> semi }
        rule(:statements)         { statement >> (space.maybe >> statement).repeat >> space.maybe }
        
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
        when :virtual
          rv = { 'section' => '_virtual' }
        when :local
          rv = { 'section' => '_local', 'key' => opr[t][:key].to_s }
        end

        rv.merge('type' => 'reference') if rv
      end

      def build_value_operand(opr)
        t = opr.keys.first
        case t
        when :string
          { 'type' => 'string', 'value' => maybe_convert_value(opr[t].to_s) }
        when :number
          { 'type' => 'number', 'value' => maybe_convert_value(opr[t].to_s) }
        end
      end

      def build_assignment_operand(opr)
        build_reference_operand(opr) || build_value_operand(opr.fetch(:value, {}))
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
          build_value_operand(opr[t])
        else
          { 'type' => 'unk' }
        end
      end
      
      def build_expr(expr)
        {
          'left'  => build_operand(expr[:left]),
          'right' => build_operand(expr[:right]),
          'op'    => OPS.fetch(expr[:op].to_s, 'unk'),
        }
      end

      def build_column(col)
        source = col[:source].to_s
        {
          table: build_reference_operand(col[:reference]),
          col: {
            'name'       => col.fetch(:name, source).to_s,
            'source'     => source,
            'expr'       => build_expr(col[:expr]),
          }
        }
      end

      def build_column_import(col)
        {
          table: build_reference_operand(col[:reference]),
          col: {
            'columns' => col.fetch(:column_names, []).map { |o| o[:name].to_s },
          }
        }
      end
      
      def build_columns(cols)
        cols.map do |col|
          t = col.keys.first
          case t
          when :column
            build_column(col[t])
          when :column_import
            build_column_import(col[t])
          end
        end.inject({}) do |o, col|
          table_name = col[:table]
          table_cols = o.fetch(table_name, [])
          o.merge(table_name => table_cols + [col[:col]])
        end.map do |k, v|
          {
            'table'   => k,
            'sources' => v
          }
        end
      end
      
      def build_assemble(stm)
        cols = stm[:columns]
        cols = [cols] if cols.class == Hash
        {
          'table_name' => stm[:table_name].to_s,
          'columns'    => build_columns(cols),
        }
      end

      def build_filter(stm)
        whens = stm.fetch(:whens, [])
        whens = [whens] if whens.class == Hash
        {
          'table'   => build_reference_operand(stm[:table]),
          'filters' => whens.map do |when_stm|
            build_expr(when_stm[:expr])
          end
        }
      end
      
      def build_keep(stm)
        { 'table_name' => stm[:table_name].to_s }
      end

      def build_assignment_expr(expr)
        at = expr.keys.first
        case at
        when :function
          {
            "type" => "function",
            "name" => expr[at][:name].to_s,
            "args" => expr[at][:args].map(&method(:build_assignment_expr)),
          }
        else
          build_assignment_operand(expr)
        end
      end
      
      def build_assignment(stm)
        assigns = stm[:assignments]
        assigns = [assigns] if assigns.class == Hash
        {
          'table' => build_reference_operand(stm[:table]),
          'assignments' => assigns.inject([]) do |a, assign|
            a + [build_assignment_expr(assign[:expr]).merge({ 'column' => assign[:name].to_s })]
          end
        }
      end

      def build_when(stm)
        {
          'expr' => build_expr(stm[:expr]),
        }
      end

      def parse(content)
        @step_fns ||= {
          assemble: method(:build_assemble),
          filter: method(:build_filter),
          keep: method(:build_keep),
          map: method(:build_assignment),
          revise: method(:build_assignment),
        }

        content = content.split(/\n/).map { |ln| ln.gsub(/\#.*/, '') }.join('')

        tree = content.empty? ? [] : ActionParser.new.parse(content)
        tree = [tree] if tree.class == Hash

        tree.inject({}) do |o, stms|
          t = stms.keys.first
          stm = stms[t]

          case t
          when :when
            expr = build_when(stm)
            whens = o.fetch('whens', {})
            section = expr['expr']['left']['section']
            o.merge('whens' => whens.merge(section => whens.fetch(section, []) + [expr]))
          when :require
            req = [:package, :id, :version].inject({}) do |o, k|
              o.merge(k.to_s => stm[:reference][k].to_s)
            end
            indexes = stm.fetch(:indexes, []).map { |col| col[:column].to_s }
            name = stm.fetch(:name, req['id']).to_s
            o.merge('requires' => o.fetch('requires', []) + [req.merge('indexes' => indexes, 'name' => name)])
          else
            o.merge('steps' => o.fetch('steps', []) + [@step_fns[t].call(stm).merge('name' => t.to_s)])
          end
        end
      end
    end
  end
end
