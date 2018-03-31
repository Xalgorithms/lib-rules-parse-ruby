require 'multi_json'
require 'radish/expects'
require 'xa/rules/parse'

describe XA::Rules::Parse do
  include XA::Rules::Parse
  include Radish::Expects

  it 'should parse individual keyword syntax' do
    files = [
      'assemble',
      'filter',
      'keep',
      'map',
      'require',
      'revise',
      'when',
      'whitespace',
    ].map { |n| "spec/files/keywords/#{n}.json" }
    load_expects(files, method(:parse)) do |ex, ac|
      expect(ac).to eql(ex)
    end
  end

  it 'should parse complete rule files' do
    files = Dir.glob('spec/files/rules/*.rule')
    files.each do |ffn|
      (dn, fn) = File.split(ffn)
      ex = MultiJson.decode(File.read(File.join(dn, "#{File.basename(ffn, '.rule')}.json")))
      expect(parse(IO.read(ffn))).to eql(ex)
    end
  end
end
