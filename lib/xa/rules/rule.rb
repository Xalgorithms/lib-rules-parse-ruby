require 'ostruct'
require 'xa/hash/deep'

module XA
  module Rules
    class Rule
      def initialize(opts)
        @opts = OpenStruct.new(opts)
      end

      def execute(doc)
        @opts.mutations.inject({}) do |chs, m|
          k = m['key']
          chs.merge(k => OpenStruct.new(
                      key:      k,
                      original: doc.deep_fetch(k),
                      mutated:  interpret(doc, m['value']),
                    ))
        end
      end

      def interpret(doc, v)
        rv = v
        if String == v.class && v.start_with?('$')
          rv = doc.deep_fetch(v[1..-1])
        end

        rv
      end
    end
  end
end
