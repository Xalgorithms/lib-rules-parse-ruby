module XA
  module Rules
    module Interpret
      def interpret(o)
        r = XA::Rules::Rule.new
        interpret_meta(o.fetch('meta', {}), r)
        interpret_commands(o.fetch('commands', []), r)
        r
      end

      private

      COMMANDS = [
        'apply',
        'expects',
      ]

      def interpret_meta(meta, r)
        meta.fetch('expects', {}).each do |args|
          r.expects(*args)
        end
      end

      def interpret_commands(commands, r)
        commands.each do |c|
          interpretation(c.fetch('type', nil)) do |fn|
            fn.call(r, c)
          end
        end
      end
      
      def interpret_apply(r, c)
        r.apply(c['function']['name'], c['function']['args']).using(c['args']['left'], c['args']['right'])
      end

      def interpret_unknown(r, c)
      end
      
      def interpretation(t)
        @interpretations ||= ['apply'].inject({}) do |o, t|
          o.merge(t => method("interpret_#{t}"))
        end
        
        yield(@interpretations.fetch(t, method(:interpret_unknown)))
      end
    end
  end
end
