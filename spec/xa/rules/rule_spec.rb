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
  end
end
