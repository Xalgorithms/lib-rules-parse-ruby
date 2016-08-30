module XA
  module Util
    module Tables
      def tables_to_documents(tables)
        tables.values.inject(nil) do |docs, table|
          docs ? table.each_with_index.map { |o, i| i < docs.length ? docs[i].merge(o) : o } : table
        end
      end
    end
  end
end
