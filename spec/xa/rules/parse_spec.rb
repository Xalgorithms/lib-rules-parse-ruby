require 'xa/rules/parse'

describe XA::Rules::Parse do
  include XA::Rules::Parse

  it 'parses' do
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

      {
        in: [
          'COMMIT foo[a, b]',
          'COMMIT bar[p, q, r]',
          'COMMIT baz',
        ],
        out: {
          'actions'   => [
            {
              'name'    => 'commit',
              'table'   => 'foo',
              'columns' => ['a', 'b'],
             },
            {
              'name'    => 'commit',
              'table'   => 'bar',
              'columns' => ['p', 'q', 'r'],
            },
            {
              'name'    => 'commit',
              'table'   => 'baz',
            },
          ],
        },
      },
      
      {
        in: [
          'JOIN USING [[a, b], [x, y]] INCLUDE [p AS pp, q]',
          'INCLUSION USING [[r, s], [zz, yy]] INCLUDE [r AS rr, s AS ss]',
        ],
        out: {
          'actions' => [
            {
              'name' => 'join',
              'using' => {
                'left'  => ['a', 'b'],
                'right' => ['x', 'y'],
              },
              'include' => {
                'p' => 'pp',
                'q' => 'q',
              },
            },
            {
              'name' => 'inclusion',
              'using' => {
                'left'  => ['r', 's'],
                'right' => ['zz', 'yy'],
              },
              'include' => {
                'r' => 'rr',
                's' => 'ss',
              },
            },
          ],
        },
      }
    ]

    expectations.each do |ex|
      expect(parse(ex[:in])).to eql(ex[:out])
    end
  end
end
