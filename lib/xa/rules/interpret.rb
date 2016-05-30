module XA
  module Rules
    module Interpret
      def interpret(o)
        r = XA::Rules::Rule.new
        interpret_meta(o.fetch('meta', {}), r)
        interpret_actions(o.fetch('actions', []), r)
        r
      end

      private

      ACTIONS = ['join', 'inclusion']
      
      def interpret_meta(meta, r)
        meta.fetch('expects', {}).each do |args|
          r.expects(*args)
        end
      end

      def interpret_actions(actions, r)
        actions.each do |c|
          interpretation(c.fetch('name', nil)) do |fn|
            fn.call(r, c)
          end
        end
      end
      
      def interpret_join(r, c)
        interpret_joinish(:join, r, c)
      end

      def interpret_inclusion(r, c)
        interpret_joinish(:inclusion, r, c)
      end

      def interpret_joinish(action, r, c)
        r.send(action).using(c['using']['left'], c['using']['right']).include(c['include'])
      end
      
      def interpret_unknown(r, c)
      end
      
      def interpretation(t)
        @interpretations ||= ACTIONS.inject({}) do |o, t|
          o.merge(t => method("interpret_#{t}"))
        end
        
        yield(@interpretations.fetch(t, method(:interpret_unknown)))
      end
    end
  end
end
