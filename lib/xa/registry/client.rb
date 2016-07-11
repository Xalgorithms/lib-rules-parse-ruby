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

      def rules(ns, name, version)
        get_rule(ns, name, version)
      end
      
      def tables(ns, name, version)
        rv = get_rule(ns, name, version)
        rv = rv['rows'] if rv && rv.key?('rows')
        rv
      end

      private

      def get_rule(ns, name, version)
        resp = @conn.get("/api/v1/rules/#{ns}/#{name}/#{version}")
        resp.success? ? resp.body : nil
      end
    end
  end
end
