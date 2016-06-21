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
          'PULL repo0:foo:1234 AS foo0',
          'PULL repo1:bar:3333 AS bar1',
          'ATTACH http://www.example0.org/foo AS repo0',
          'ATTACH http://www.example1.org/foo AS repo1',
        ],
        out: {
          'meta' => {
            'repositories' => {
              'repo0' => 'http://www.example0.org/foo',
              'repo1' => 'http://www.example1.org/foo',
            },
            'tables' => {
              'foo0' => {
                'repository' => 'repo0',
                'name'       => 'foo',
                'version'    => '1234',
              },
              'bar1' => {
                'repository' => 'repo1',
                'name'       => 'bar',
                'version'    => '3333',
              },
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
          'PUSH foo',
          'POP',
          'DUPLICATE',
          'PUSH bar',
        ],
        out: {
          'actions'   => [
            {
              'name'    => 'push',
              'table'   => 'foo',
             },
            {
              'name'    => 'pop',
            },
            {
              'name'    => 'duplicate',
            },
            {
              'name'    => 'push',
              'table'   => 'bar',
             },
          ],
        },
      },

      {
        in: [
          'INVOKE repo0:name0:1111',
          'INVOKE repo1:name2:3333',
        ],
        out: {
          'actions' => [
            {
              'name'       => 'invoke',
              'repository' => 'repo0',
              'rule'       => 'name0',
              'version'    => '1111',
            },
            {
              'name'       => 'invoke',
              'repository' => 'repo1',
              'rule'       => 'name2',
              'version'    => '3333',
            },
          ],
        },
      },
      
      {
        in: [
          'JOIN USING [[a, b], [x, y]] INCLUDE [p]',
          'JOIN USING [[a, b], [x, y]] INCLUDE [p AS pp, q]',
          'INCLUSION USING [[r, s], [zz, yy]] INCLUDE [r AS rr, s AS ss]',
          'ACCUMULATE foo USING mult(a, b, c) AS baz',
          'ACCUMULATE bar USING add(p, q)',
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
                'p' => 'p',
              },
            },
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
            {
              'name'     => 'accumulate',
              'column'   => 'foo',
              'result'   => 'baz',
              'function' => {
                  'name' => 'mult',
                  'args' => ['a', 'b', 'c'],
              },
            },
            {
              'name'   => 'accumulate',
              'column' => 'bar',
              'function' => {
                  'name' => 'add',
                  'args' => ['p', 'q'],
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
