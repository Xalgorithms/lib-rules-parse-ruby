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

      def tables(ns, name, version)
        rv = nil
        resp = @conn.get("/api/v1/rules/#{ns}/#{name}/#{version}")
        if resp.success?
          if resp.body.key?('rows')
            rv = resp.body['rows']
          else
            Rails.logger.warn('? does not appear to be a table')
          end
        end

        rv
      end
    end
  end
end
