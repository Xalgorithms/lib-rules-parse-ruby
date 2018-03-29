require 'multi_json'
require 'radish/expects'
require 'xa/rules/parse'

describe XA::Rules::Parse do
  include XA::Rules::Parse
  include Radish::Expects

  it 'should parse individual keyword syntax' do
    files = [
      'assemble',
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
end
