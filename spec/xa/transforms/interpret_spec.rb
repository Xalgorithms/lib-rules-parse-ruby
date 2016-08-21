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
      expect(interpret(ex[:data], ex[:in])).to eql(ex[:out])
    end
  end
end
