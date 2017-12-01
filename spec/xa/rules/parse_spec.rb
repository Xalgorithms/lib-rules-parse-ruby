require 'radish/expects'

require 'xa/rules/parse'

describe XA::Rules::Parse do
  include XA::Rules::Parse
  include Radish::Expects

  it 'should parse the syntax' do
    files = [
      'spec/files/when.json',
      'spec/files/assemble.json',
      'spec/files/map.json',
    ]

    load_expects(files, method(:parse)) do |ex, ac|
      expect(ac).to eql(ex)
    end
  end
end
