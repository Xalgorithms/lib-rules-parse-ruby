require 'xa/util/documents'
require 'xa/util/tables'

module XA
  module Transforms
    module Interpret
      include XA::Util::Documents
      include XA::Util::Tables
      
      def interpret(src, tx)
        tx.keys.inject({}) do |tables, tn|
          m = tx[tn]
          docs = src.map do |doc|
            transform_by_inverted_map(doc, m)
          end
          tables.merge(tn => docs)
        end
      end

      def misinterpret(tables, tx)
        tables_to_documents(tables).map do |doc|
          transformed = tx.values.map do |m|
            transform_by_map(doc, m)
          end
          combine_documents(transformed)
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
