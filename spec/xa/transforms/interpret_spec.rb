require 'xa/transforms/interpret'

describe XA::Transforms::Interpret do
  include XA::Transforms::Interpret

  it 'builds tables' do
    expectations = [
      {
        # success case
        in: {
          'foo' => {
            'p' => 'x.y.z',
            'q' => 'a.b.c'
          },
          'bar' => {
            'z' => 'x.y.q',
            'y' => 'd',
          },
        },
        out: {
          'foo' => [
            { 'p' => 'z00', 'q' => 'c00' },
            { 'p' => 'z01', 'q' => 'c01' },
          ],
          'bar' => [
            { 'z' => 'q00', 'y' => 'd00' },
            { 'z' => 'q01', 'y' => 'd01' },
          ]
        },
        changes: {
          'p' => 'change/p',
          'y' => 'change/y',
        },
        rev: [
          {
            'x' => {
              'y' => {
                'z' => 'change/p',
                'q' => 'q00',
              },
            },
            'a' => {
              'b' => {
                'c' => 'c00',
              },
            },
            'd' => 'change/y',
          },
          {
            'x' => {
              'y' => {
                'z' => 'change/p',
                'q' => 'q01',
              },
            },
            'a' => {
              'b' => {
                'c' => 'c01',
              },
            },
            'd' => 'change/y',
          },
        ],
        data: [
          {
            'x' => {
              'y' => {
                'z' => 'z00',
                'q' => 'q00',
              },
            },
            'a' => {
              'b' => {
                'c' => 'c00',
              }
            },
            'd' => 'd00',
          },
          {
            'x' => {
              'y' => {
                'z' => 'z01',
                'q' => 'q01',
              },
            },
            'a' => {
              'b' => {
                'c' => 'c01',
              }
            },
            'd' => 'd01',
          },
        ],
      },
      {
        in: {
          'foo' => {
            'p' => 'x.y.z',
            'q' => 'a.b.c',
            'r' => 'd',
          },
        },
        out: {
          'foo' => [
            { 'p' => 'z00', 'r' => 'd00', },
            { 'q' => 'c01' },
          ],
        },
        changes: {
          'r' => 'change/r',
          'q' => 'change/q',
        },
        rev: [
          {
            'x' => {
              'y' => {
                'z' => 'z00',
              },
            },
            'd' => 'change/r',
          },
          {
            'a' => {
              'b' => {
                'c' => 'change/q',
              }
            },
          },
        ],
        data: [
          {
            'x' => {
              'y' => {
                'z' => 'z00',
              },
            },
            'd' => 'd00',
          },
          {
            'x' => {
              'y' => {
                'q' => 'q01',
              },
            },
            'a' => {
              'b' => {
                'c' => 'c01',
              }
            },
          },
        ],
      }
    ]

    expectations.each do |ex|
      interpreted = interpret(ex[:data], ex[:in])
      expect(interpreted).to eql(ex[:out])

      # change the data and reverse transform
      changed = interpreted.keys.inject({}) do |o, k|
        changed_rows = interpreted[k].map do |row|
          row.keys.inject({}) do |co, rk|
            co.merge(rk => ex[:changes].fetch(rk, row[rk]))
          end
        end
        o.merge(k => changed_rows)
      end

      expect(misinterpret(changed, ex[:in])).to eql(ex[:rev])
    end
  end
end
