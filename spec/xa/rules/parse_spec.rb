require 'multi_json'
require 'radish/expects'
require 'xa/rules/parse'

describe XA::Rules::Parse do
  include XA::Rules::Parse
  include Radish::Expects

  [
    'assemble',
    'filter',
    'keep',
    'map',
    'require',
    'revise',
    'when',
    'whitespace',
  ].each do |n|
    it "should parse syntax for #{n.upcase}" do
      load_expects(["spec/files/keywords/#{n}.json"], method(:parse)) do |ex, ac|
        expect(ac).to eql(ex)
      end
    end
  end

  Dir.glob('spec/files/rules/*.rule').each do |ffn|
    (dn, fn) = File.split(ffn)
    it "should parse: #{fn}" do
      ex = MultiJson.decode(File.read(File.join(dn, "#{File.basename(ffn, '.rule')}.json")))
      expect(parse(IO.read(ffn))).to eql(ex)
    end
  end
end
