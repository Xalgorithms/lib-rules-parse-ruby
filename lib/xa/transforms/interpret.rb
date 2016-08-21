module XA
  module Transforms
    module Interpret
      def interpret(src, tx)
        maps = tx.keys.inject({}) do |o, col_key|
          o.merge(col_key => {
                    make: lambda do |src_o|
                      make_row(src_o, tx[col_key])
                    end,
                    table: []
                  })
        end

        src.each do |src_o|
          maps.values.each do |v|
            v[:table] << v[:make].call(src_o)
          end
        end

        maps.inject({}) do |o, kv|
          o.merge(kv.first => kv.last[:table])
        end
      end

      private

      def make_row(o, tx)
        tx.inject({}) do |r, kv|
          val = find(o, kv.last)
          val ? r.merge(kv.first => val) : r
        end
      end

      def find(o, ks)
        parts = ks.split('.')
        len = parts.length
        
        (0...len).inject(o) { |o, i| o.fetch(parts[i], (i == len - 1) ? nil : {}) }
      end
    end
  end
end
