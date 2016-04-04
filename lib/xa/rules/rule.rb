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
          chs.merge(m[:key] => OpenStruct.new(
                      key:      m[:key],
                      original: doc.deep_fetch(m[:key]),
                      mutated:  m[:value],
                    ))
        end
      end
    end
  end
end
