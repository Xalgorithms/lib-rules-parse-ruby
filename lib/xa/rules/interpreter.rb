module XA
  module Rules
    class Interpreter
      def execute(doc, rules)
        rules.map { |rule| rule.execute(doc) }
      end

      def apply(doc, changes)
        changes.each do |ch|
          doc.deep_set(ch.key, ch.mutated)
        end
      end
    end
  end
end
