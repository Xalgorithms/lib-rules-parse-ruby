module XA
  module Rules
    class Interpreter
      def execute(doc, rules)
        rules.map { |rule| rule.execute(doc) }
      end
    end
  end
end
