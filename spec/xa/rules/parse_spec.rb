require 'xa/rules/parse'

describe XA::Rules::Parse do
  include XA::Rules::Parse

  it 'parses expect statements' do
    expectations = [
      {
        in: [
          'EXPECTS foo[x, y, z]',
          'ExPeCTS bar[a, b]',
        ],
        out: {
          'meta' => {
            'expects' => {
              'foo' => ['x', 'y', 'z'],
              'bar' => ['a', 'b'],
            },
          }
        },
      },
    ]

    expectations.each do |ex|
      expect(parse(ex[:in])).to eql(ex[:out])
    end
  end
end
