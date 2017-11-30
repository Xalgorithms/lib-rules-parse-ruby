require 'parslet'

module XA
  module Rules
    module Parse
      class ActionParser < Parslet::Parser
        # rule(:comma)        { str(',') }
        # rule(:colon)        { str(':') }
        # rule(:lblock)       { str('[') }
        # rule(:rblock)       { str(']') }
        # rule(:lparen)       { str('(') }
        # rule(:rparen)       { str(')') }
        
        # rule(:space)        { match('\s').repeat(1) }
        # rule(:ass)          { str('AS') }
        # rule(:usings)       { str('USING') }
        # rule(:includes)     { str('INCLUDE') }
        # rule(:pushs)        { str('PUSH') }
        # rule(:pops)         { str('POP') }
        # rule(:duplicates)   { str('DUPLICATE') }
        # rule(:pulls)        { str('PULL') }
        # rule(:attachs)      { str('ATTACH') }
        # rule(:invokes)      { str('INVOKE') }

        # rule(:names)        { name >> (comma >> space.maybe >> name).repeat }
        # rule(:name)         { match('\w+').repeat(1) }
        # rule(:names_as)     { name_as >> (comma >> space.maybe >> name_as).repeat }
        # rule(:name_as)      { name.as(:original) >> (space >> ass >> space >> name.as(:new)).maybe }
        # rule(:anything)     { match('[^\s]').repeat(1) }
        
        # rule(:table_ref)      { name.as(:table_name) >> lblock >> names.as(:columns) >> rblock }
        # rule(:table_ref_opt)  { name.as(:table_name) >> (lblock >> names.as(:columns) >> rblock).maybe }
        # rule(:rule_ref)       { name.as(:ns) >> colon >> name.as(:rule) >> colon >> name.as(:version) }
        # rule(:join_spec)      { lblock >> lblock >> names.as(:lefts) >> rblock >> comma >> space.maybe >> lblock >> names.as(:rights) >> rblock >> rblock }
        # rule(:includes_spec)  { lblock >> names_as >> rblock }
        # rule(:joinish)        { usings >> space >> join_spec.as(:joins) >> space >> includes >> space >> includes_spec.as(:includes) }

        # rule(:expects)        { name.as(:action) >> space >> table_ref }
        # rule(:commit)         { name.as(:action) >> space >> table_ref_opt }
        # rule(:push)           { pushs.as(:action) >> space >> name.as(:table_name) }
        # rule(:pop)            { pops.as(:action) }
        # rule(:duplicate)      { duplicates.as(:action) }
        # rule(:pull)           { pulls.as(:action) >> space >> rule_ref.as(:rule_ref) >> space >> ass >> space >> name.as(:table_name) }
        # rule(:attach)         { attachs.as(:action) >> space >> anything.as(:url) >> space >> ass >> space >> name.as(:name) }
        # rule(:invoke)         { invokes.as(:action) >> space >> rule_ref.as(:rule_ref) }
        # rule(:func)           { name.as(:name) >> lparen >> names.as(:args) >> rparen }
        
        # rule(:table_action)   { expects | commit }
        # rule(:joinish_action) { name.as(:action) >> space >> joinish }
        # rule(:reduce_action)  { name.as(:action) >> space >> name.as(:column) >> space >> usings >> space >> func.as(:function) >> (space >> ass >> space >> name.as(:result)).maybe }
        # rule(:stack_action)   { push | pop | duplicate }
        # rule(:repo_action)    { attach | pull }
        # rule(:rule_action)    { invoke }
        # rule(:action)         { table_action | joinish_action | reduce_action | stack_action | repo_action | rule_action }

        root(:action)
      end

      def parse_buffer(b, logger=nil)
        parse(b.split(/\r?\n/).inject([]) do |a, ln|
                ln.strip!
                (ln.empty? || ln.start_with?('#')) ? a : a + [ln]
              end, logger)
      end
      
      def parse(actions, logger=nil)
        rv = {}
        actions.each do |act|
          logger.debug("try to parse: #{act}") if logger
          res = parser.parse(act)
          rv = rv.merge(interpret(rv, res))
        end
        rv
      end
    end
  end
end
