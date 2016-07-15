require 'xa/registry/client'

module XA
  module Rules
    class Context
      def initialize(tables = {})
        @clients = {}
        @types = {
          table: method(:get_table),
          rule:  method(:get_rule),
        }
        @tables = tables
      end
      
      def get(type, args, &bl)
        @types.fetch(type, method(:get_nothing)).call(args, &bl)
      end

      def execute(rule)
        rule.repositories do |url, name|
          init_client(name, url)
        end
        rule.execute(self, @tables)
      end

      private

      def init_client(name, url)
        if !@clients.key?(name)
          cl = XA::Registry::Client.new(url)
          @clients[name] = {
            client:     cl,
            namespaces: cl.namespaces,
          }
        end
      end
      
      def with_client(ns)
        # TODO: deal with multiple registries some time in the future
        cl = @clients.values.select { |cl| cl[:namespaces].include?(ns) }.first[:client]
        yield(cl) if cl
      end

      def invoke_client(args, m, t, &bl)
        with_client(args[:ns]) do |cl|
          bl.call(cl.send(m, args[:ns], args[t], args[:version])) if bl
        end
      end
      
      def get_table(args, &bl)
        invoke_client(args, :tables, :table, &bl)
      end

      def get_rule(args, &bl)
        invoke_client(args, :rules, :rule, &bl)
      end

      def get_nothing(args, &bl)
      end
    end
  end
end
