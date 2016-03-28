require 'ostruct'

module XA
  module Rules
    class Rule
      def initialize(opts)
        @opts = OpenStruct.new(opts)
      end

      def execute(doc)
        @opts.mutations.inject({}) do |chs, m|
          chs.merge(m[:key] => OpenStruct.new(
                      original: deep_fetch(doc, m[:key]),
                      mutated:  m[:value],
                    ))
        end
      end

      private

      def do_deep_fetch(h, keys)
        if keys.length == 1
          h.fetch(keys.first, nil)
        else
          do_deep_fetch(h.fetch(keys.first, {}), keys[1..-1])
        end
      end
      
      def deep_fetch(h, k)
        do_deep_fetch(h, k.split('.'))
      end
    end
  end
end
