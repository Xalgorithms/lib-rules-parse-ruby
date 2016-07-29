require 'xa/transforms/parse'

describe XA::Transforms::Parse do
  include XA::Transforms::Parse
  
  it 'parses' do
    expectations = [
      {
        in: [
          'ADAPTS transaction',
          'MAKE foo',
          'USE x.y.z AS p',
          'USE a.b.c AS q',
          'MAKE bar',
          'USE d.e.f AS z',
          'USE g.h AS y',
        ],
        out: {
          'adapts' => 'transaction',
          'tables' => {
            'foo' => {
              'p' => 'x.y.z',
              'q' => 'a.b.c'
            },
            'bar' => {
              'z' => 'd.e.f',
              'y' => 'g.h',
            },
          },
        },
      },
      {
        in: [
          'ADAPTS invoice',
          'USE d AS e',
          'MAKE baz',
        ],
        out: {
          'adapts' => 'invoice',
          'tables' => {
            'baz' => {},
          },
        },
      },
    ]

    expectations.each do |ex|
      expect(parse(ex[:in])).to eql(ex[:out])
    end
  end
end
