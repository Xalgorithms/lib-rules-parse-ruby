require 'parslet'

module XA
  module Rules
    module Parse
      class ActionParser < Parslet::Parser
        rule(:comma)        { str(',') }
        rule(:lblock)       { str('[') }
        rule(:rblock)       { str(']') }
        
        rule(:space)        { match('\s').repeat(1) }

        rule(:names)        { name >> (comma >> space.maybe >> name).repeat }
        rule(:name)         { match('[a-zA-Z]').repeat(1) }
        rule(:table_ref)    { name.as(:table_name) >> lblock >> names.as(:columns) >> rblock }

        rule(:table_action) { name.as(:action) >> space.repeat(1) >> table_ref  }
        rule(:action)       { table_action }

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

      def interpret(o, res)
        send("interpret_#{res.fetch(:action, 'nothing').str.downcase}", o, res)
      end

      def interpret_expects(o, res)
        meta = o.fetch('meta', {})
        expects = meta.fetch('expects', {}).merge(
          res[:table_name].str => res[:columns].str.split(/\,\s+/))
        meta = meta.merge('expects' => expects)
        o.merge('meta' => meta)
      end
      
      def parser
        @parser ||= ActionParser.new
      end
    end
  end
end
