require 'xa/repository/client'

module XA
  module Rules
    class Context
      def initialize
        @clients = {}
        @types = {
          table: method(:get_table)
        }
      end
      
      def get(type, args, &bl)
        @types.fetch(type, method(:get_nothing)).call(args, &bl)
      end

      def execute(rule)
        rule.repositories do |url, name|
          @clients[name] = XA::Repository::Client.new(url) if !@clients.key?(name)
        end
        rule.execute(self, {})
      end

      private

      def get_table(args, &bl)
        if @clients.key?(args[:repo])
          bl.call(@clients[args[:repo]].tables(args[:table], args[:version])) if bl
        end
      end

      def get_nothing(args, &bl)
      end
    end
  end
end
