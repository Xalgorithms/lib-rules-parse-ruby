require 'parslet'

module XA
  module Rules
    module Parse
      class ActionParser < Parslet::Parser
        rule(:comma)        { str(',') }
        rule(:lblock)       { str('[') }
        rule(:rblock)       { str(']') }
        
        rule(:space)        { match('\s').repeat(1) }
        rule(:ass)          { str('AS') }
        rule(:usings)       { str('USING') }
        rule(:includes)     { str('INCLUDE') }
        rule(:pushs)        { str('PUSH') }
        rule(:pops)         { str('POP') }
        rule(:duplicates)   { str('DUPLICATE') }

        rule(:names)        { name >> (comma >> space.maybe >> name).repeat }
        rule(:name)         { match('\w+').repeat(1) }
        rule(:names_as)     { name_as >> (comma >> space.maybe >> name_as).repeat }
        rule(:name_as)      { name.as(:original) >> (space >> ass >> space >> name.as(:new)).maybe }
        
        rule(:table_ref)      { name.as(:table_name) >> lblock >> names.as(:columns) >> rblock }
        rule(:table_ref_opt)  { name.as(:table_name) >> (lblock >> names.as(:columns) >> rblock).maybe }
        rule(:join_spec)      { lblock >> lblock >> names.as(:lefts) >> rblock >> comma >> space.maybe >> lblock >> names.as(:rights) >> rblock >> rblock }
        rule(:includes_spec)  { lblock >> names_as >> rblock }
        rule(:joinish)        { usings >> space >> join_spec.as(:joins) >> space >> includes >> space >> includes_spec.as(:includes) }

        rule(:expects)        { name.as(:action) >> space >> table_ref }
        rule(:commit)         { name.as(:action) >> space >> table_ref_opt }
        rule(:push)           { pushs.as(:action) >> space >> name.as(:table_name) }
        rule(:pop)            { pops.as(:action) }
        rule(:duplicate)      { duplicates.as(:action) }
        
        rule(:table_action)   { expects | commit }
        rule(:joinish_action) { name.as(:action) >> space >> joinish }
        rule(:stack_action)   { push | pop | duplicate }
        rule(:action)         { table_action | joinish_action | stack_action }

        root(:action)
      end
      
      def parse(actions)
        rv = {}
        actions.each do |act|
          begin
            res = parser.parse(act)
            rv = rv.merge(interpret(rv, res))
          rescue Exception => e
            p e
          end
        end
        rv
      end

      private

      def split_names(names)
        names.str.split(/\,\s+/)
      end
      
      def interpret(o, res)
        send("interpret_#{res.fetch(:action, 'nothing').str.downcase}", o, res)
      end

      def interpret_expects(o, res)
        meta = o.fetch('meta', {})
        expects = meta.fetch('expects', {}).merge(
          res[:table_name].str => split_names(res[:columns]))
        meta = meta.merge('expects' => expects)
        o.merge('meta' => meta)
      end

      def interpret_push(o, res)
        add_action(o, 'name'  => 'push', 'table' => res[:table_name].str)
      end

      def interpret_pop(o, res)
        add_action(o, 'name'  => 'pop')
      end

      def interpret_duplicate(o, res)
        add_action(o, 'name'  => 'duplicate')
      end
      
      def interpret_commit(o, res)
        add_action(o, {
          'name'  => 'commit',
          'table' => res[:table_name].str,
        }.tap do |a|
          a['columns'] = split_names(res[:columns]) if res.key?(:columns)
        end)
      end

      def interpret_join(o, res)
        interpret_joinish(o, res)
      end

      def interpret_inclusion(o, res)
        interpret_joinish(o, res)
      end
      
      def interpret_joinish(o, res)
        add_action(o, {
          'name'    => res[:action].str.downcase,
          'using'   => {
            'left'  =>  split_names(res[:joins][:lefts]),
            'right' => split_names(res[:joins][:rights]),
          },
          'include' => res[:includes].inject({}) do |o, i|
            o.merge(i[:original].str => i.key?(:new) ? i[:new].str : i[:original].str)
          end
        })
      end

      def add_action(o, act)
        o.merge('actions' => o.fetch('actions', []) << act)
      end
      
      def parser
        @parser ||= ActionParser.new
      end
    end
  end
end
