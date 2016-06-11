require 'parslet'

module XA
  module Rules
    module Parse
      class ActionParser < Parslet::Parser
        rule(:comma)        { str(',') }
        rule(:colon)        { str(':') }
        rule(:lblock)       { str('[') }
        rule(:rblock)       { str(']') }
        
        rule(:space)        { match('\s').repeat(1) }
        rule(:ass)          { str('AS') }
        rule(:usings)       { str('USING') }
        rule(:includes)     { str('INCLUDE') }
        rule(:pushs)        { str('PUSH') }
        rule(:pops)         { str('POP') }
        rule(:duplicates)   { str('DUPLICATE') }
        rule(:pulls)        { str('PULL') }
        rule(:attachs)      { str('ATTACH') }
        rule(:invokes)      { str('INVOKE') }

        rule(:names)        { name >> (comma >> space.maybe >> name).repeat }
        rule(:name)         { match('\w+').repeat(1) }
        rule(:names_as)     { name_as >> (comma >> space.maybe >> name_as).repeat }
        rule(:name_as)      { name.as(:original) >> (space >> ass >> space >> name.as(:new)).maybe }
        rule(:anything)     { match('[^\s]').repeat(1) }
        
        rule(:table_ref)      { name.as(:table_name) >> lblock >> names.as(:columns) >> rblock }
        rule(:table_ref_opt)  { name.as(:table_name) >> (lblock >> names.as(:columns) >> rblock).maybe }
        rule(:rule_ref)       { name.as(:repo) >> colon >> name.as(:rule) >> colon >> name.as(:version) }
        rule(:join_spec)      { lblock >> lblock >> names.as(:lefts) >> rblock >> comma >> space.maybe >> lblock >> names.as(:rights) >> rblock >> rblock }
        rule(:includes_spec)  { lblock >> names_as >> rblock }
        rule(:joinish)        { usings >> space >> join_spec.as(:joins) >> space >> includes >> space >> includes_spec.as(:includes) }

        rule(:expects)        { name.as(:action) >> space >> table_ref }
        rule(:commit)         { name.as(:action) >> space >> table_ref_opt }
        rule(:push)           { pushs.as(:action) >> space >> name.as(:table_name) }
        rule(:pop)            { pops.as(:action) }
        rule(:duplicate)      { duplicates.as(:action) }
        rule(:pull)           { pulls.as(:action) >> space >> rule_ref.as(:rule_ref) >> space >> ass >> space >> name.as(:table_name) }
        rule(:attach)         { attachs.as(:action) >> space >> anything.as(:url) >> space >> ass >> space >> name.as(:name) }
        rule(:invoke)         { invokes.as(:action) >> space >> rule_ref.as(:rule_ref) }
        
        rule(:table_action)   { expects | commit }
        rule(:joinish_action) { name.as(:action) >> space >> joinish }
        rule(:stack_action)   { push | pop | duplicate }
        rule(:repo_action)    { attach | pull }
        rule(:rule_action)    { invoke }
        rule(:action)         { table_action | joinish_action | stack_action | repo_action | rule_action }

        root(:action)
      end
      
      def parse(actions)
        rv = {}
        actions.each do |act|
          res = parser.parse(act)
          rv = rv.merge(interpret(rv, res))
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
        add_meta(o, 'expects', res[:table_name].str => split_names(res[:columns]))
      end

      def interpret_pull(o, res)
        add_meta(o, 'tables', res[:table_name].str => {
                   'repository' => res[:rule_ref][:repo].str,
                   'name'       => res[:rule_ref][:rule].str,
                   'version'    => res[:rule_ref][:version].str,
                 })
      end

      def interpret_attach(o, res)
        add_meta(o, 'repositories', res[:name].str => res[:url].str)
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
      
      def interpret_invoke(o, res)
        act = {
          'name' => 'invoke',
          'repository' => res[:rule_ref][:repo].str,
          'rule'       => res[:rule_ref][:rule].str,
          'version'    => res[:rule_ref][:version].str,
        }
        add_action(o, act)
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

      def add_meta(o, section, d)
        meta = o.fetch('meta', {})
        sec = meta.fetch(section, {}).merge(d)
        meta = meta.merge(section => sec)
        o.merge('meta' => meta)
      end
      
      def parser
        @parser ||= ActionParser.new
      end
    end
  end
end
