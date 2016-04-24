require 'xa/rules/rule'

describe XA::Rules::Rule do
  context 'meta information' do
    it 'a rule should contain meta information about which tables and columns are required' do 
      r = XA::Rules::Rule.new
      expected = {
        'foo' => ['x', 'y'],
        'bar' => ['a', 'b'],
      }
      expected.each do |tn, cols|
        r.expects(tn, cols)
      end

      expect(r.meta.expects.length).to eql(expected.keys.length)
      actual = r.meta.expects.inject({}) do |o, ex|
        o.merge(ex.table => ex.columns)
      end

      expect(actual).to eql(expected)
    end
  end

  context 'execution' do
    it 'fails execution if expectations are not met' do
      r = XA::Rules::Rule.new

      res = r.execute({})
      expect(res).to_not be_nil
      expect(res.status).to eql(:ok)
      expect(res.failures).to be_empty

      r.expects('foo', ['a', 'b'])

      res = r.execute({})
      expect(res).to_not be_nil
      expect(res.status).to eql(:missing_expected_table)
      expect(res.failures).to_not be_empty
      expect(res.failures.first).to eql('foo')

      res = r.execute('foo' => [])
      expect(res).to_not be_nil
      expect(res.status).to eql(:ok)
      expect(res.failures).to be_empty
    end

    it 'joins two tables' do
      r = XA::Rules::Rule.new

      tables = {
        'foo' => [
          { 'x' => 1, 'y' => 2, 'z' => 1 },
          { 'x' => 2, 'y' => 2, 'z' => 2 },
          { 'x' => 1, 'y' => 1, 'z' => 3 },
          { 'x' => 3, 'y' => 3, 'z' => 4 },
        ],
        'bar' => [
          { 'a' => 1, 'b' => 1, 'c' => 0 },
          { 'a' => 2, 'b' => 2, 'c' => 1 },
        ]
      }

      expected = [
        {
          table: 'foo',
          join:  ['bar', ['x', 'y'], ['a', 'b']],
          final: {
            'foo' => [
              { 'x' => 1, 'y' => 2, 'z' => 1 },
              { 'x' => 2, 'y' => 2, 'z' => 2, 'a' => 2, 'b' => 2, 'c' => 1 },
              { 'x' => 1, 'y' => 1, 'z' => 3, 'a' => 1, 'b' => 1, 'c' => 0 },
              { 'x' => 3, 'y' => 3, 'z' => 4 },
            ],
            'bar' => [
              { 'a' => 1, 'b' => 1, 'c' => 0 },
              { 'a' => 2, 'b' => 2, 'c' => 1 },
            ],
          },
        },
      ]

      expected.each do |ex|
        r.use(ex[:table])
        r.apply(*ex[:join]).using(:join)
        res = r.execute(tables)
        expect(res.tables).to eql(ex[:final])
      end
    end
  end
end
