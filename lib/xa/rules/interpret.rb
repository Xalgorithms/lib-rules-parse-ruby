module XA
  module Rules
    module Interpret
      def interpret(o)
        r = XA::Rules::Rule.new
        o.fetch('expects', {}).each do |tn, cols|
          r.expects(tn, cols)
        end

        o.fetch('commands', []).each do |c|
          validate(c.first) do
            r.send(*c)
          end
        end
        
        r
      end

      def validate(name)
        @valid_command_names = Set.new(
          [
            'use',
            'apply',
          ])
        yield if @valid_command_names.include?(name)
      end
    end
  end
end
