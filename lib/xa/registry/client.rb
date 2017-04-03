require 'faraday'
require 'faraday_middleware'

module XA
  module Registry
    class Client
      def initialize(url)
        @conn = Faraday.new(url) do |f|
          f.request(:url_encoded)
          f.request(:json)
          f.response(:json, :content_type => /\bjson$/)
          f.adapter(Faraday.default_adapter)        
        end
      end

      def namespaces
        get("namespaces")
      end

      def rule_by_full_reference(ref)
        rule_by_reference(*ref.split(/:/))
      end
      
      def rule_by_reference(ns, name, version)
        get_rule(ns, name, version)
      end

      def rules(since = nil)
        since ? get("rules/since/#{since}") : get("rules")
      end
      
      def tables(ns, name, version)
        rv = get_rule(ns, name, version)
        rv = rv.fetch('content', {}).fetch('rows', []) if rv
        rv
      end

      private

      def get_rule(ns, name, version)
        get("rules/by_reference/#{ns}/#{name}/#{version}")
      end

      def get(rel_url)
        resp = @conn.get("/api/v1/#{rel_url}")
        resp.success? ? resp.body : nil
      end
    end
  end
end
