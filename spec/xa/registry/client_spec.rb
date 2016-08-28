require 'xa/registry/client'

describe XA::Registry::Client do
  include Randomness
  
  it 'should permit requesting a rule by reference' do
    rand_times.each do
      conn = double(Faraday)
      resp = double
      
      url = 'http://foo.com'

      ns = Faker::Hipster.word
      name = Faker::Hipster.word
      version = Faker::Number.number(8)

      rel_url = "/api/v1/rules/by_reference/#{ns}/#{name}/#{version}"

      expect(resp).to receive(:success?).twice.and_return(true)
      expect(resp).to receive(:body).twice.and_return({})
      expect(conn).to receive(:get).twice.with(rel_url).and_return(resp)
      expect(Faraday).to receive(:new).with(url).and_return(conn)

      cl = XA::Registry::Client.new(url)
      cl.rule_by_reference(ns, name, version)
      cl.rule_by_full_reference("#{ns}:#{name}:#{version}")
    end
  end
end
