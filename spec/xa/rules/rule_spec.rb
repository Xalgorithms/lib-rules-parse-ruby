require 'xa/rules/rule'
require 'xa/rules/context'

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

      res = r.execute(XA::Rules::Context.new, {})
      
      expect(res).to_not be_nil
      expect(res[:status]).to eql(:ok)
      expect(res[:failures]).to be_empty

      r.expects('foo', ['a', 'b'])

      res = r.execute(XA::Rules::Context.new, {})

      expect(res).to_not be_nil
      expect(res[:status]).to eql(:failure)
      expect(res[:failures]).to eql([{ reason: :missing_expected_table, details: ['foo'] }])

      res = r.execute(XA::Rules::Context.new, 'foo' => [])

      expect(res).to_not be_nil
      expect(res[:status]).to eql(:ok)
      expect(res[:failures]).to be_empty
    end

    let(:tables) do
      {
        'foo' => [
          { 'x' => 1, 'y' => 2, 'z' => 1, 'a' => 1 },
          { 'x' => 2, 'y' => 2, 'z' => 2, 'a' => 4 },
          { 'x' => 1, 'y' => 1, 'z' => 3, 'a' => 9 },
          { 'x' => 3, 'y' => 3, 'z' => 4, 'a' => 16 },
        ],
        'bar' => [
          { 'a' => 1, 'b' => 1, 'c' => 5 },
          { 'a' => 2, 'b' => 2, 'c' => 1 },
        ],
        'baz' => [
          { 'q' => 2, 'p' => 2, 'r' => 1 },
          { 'q' => 2, 'p' => 3, 'r' => 2 },
        ],
        'strs' => [
          { 'q' => '2.5', 'p' => '2', 'r' => '1' },
          { 'q' => '2', 'p' => '3.5', 'r' => '2' },
          { 'q' => '2', 'r' => '2' },
        ],
      }
    end

    it 'has basic stack operations' do
      r = XA::Rules::Rule.new
      r.push('bar')
      r.push('baz')
      r.pop
      r.push('bar')
      r.pop
      r.push('baz')

      r.commit('a')
      r.commit('b')

      res = r.execute(XA::Rules::Context.new, tables.dup)

      expect(res[:tables]['a']).to eql(tables['baz'])
      expect(res[:tables]['b']).to eql(tables['bar'])
    end
    
    it 'allows commits to specify only certain columns' do
      r = XA::Rules::Rule.new
      r.push('bar')
      r.push('baz')
      r.commit('a', ['q'])
      r.commit('b', ['a', 'c'])

      res = r.execute(XA::Rules::Context.new, tables.dup)

      expect(res[:tables]['a']).to eql(tables['baz'].map { |r| { 'q' => r['q'] } })
      expect(res[:tables]['b']).to eql(tables['bar'].map { |r| { 'a' => r['a'], 'c' => r['c'] } })
    end
    
    it 'duplicates tables' do
      expected = ['foo', 'bar', 'baz', 'bar']
      expected.each do |n|
        r = XA::Rules::Rule.new
        r.push(n)
        r.duplicate
        r.commit('a')
        r.commit('b')

        res = r.execute(XA::Rules::Context.new, tables.dup)
        
        expect(res[:tables]['a']).to eql(tables[n])
        expect(res[:tables]['b']).to eql(tables[n])
      end
    end
    
    it 'applies actions to a table' do
      expected = [
        {
          tables: ['foo', 'bar'],
          relation:  [['x', 'y'], ['a', 'b']],
          action: :join,
          final: {
            'output' => [
              { 'x' => 1, 'y' => 2, 'z' => 1, 'a' => 1 },
              { 'x' => 2, 'y' => 2, 'z' => 2, 'a' => 2, 'b' => 2, 'c' => 1 },
              { 'x' => 1, 'y' => 1, 'z' => 3, 'a' => 1, 'b' => 1, 'c' => 5 },
              { 'x' => 3, 'y' => 3, 'z' => 4, 'a' => 16 },
            ],
          },
        },
        {
          tables: ['foo', 'bar'],
          relation:  [['x'], ['a']],
          action: :join,
          include: { 'a' => 'a', 'c' => 'cc' },
          final: {
            'output' => [
              { 'x' => 1, 'y' => 2, 'z' => 1, 'a' => 1, 'cc' => 5 },
              { 'x' => 2, 'y' => 2, 'z' => 2, 'a' => 2, 'cc' => 1 },
              { 'x' => 1, 'y' => 1, 'z' => 3, 'a' => 1, 'cc' => 5 },
              { 'x' => 3, 'y' => 3, 'z' => 4, 'a' => 16 },
            ],
          },
        },
        {
          tables: ['foo', 'baz'],
          relation:  [['x'], ['q']],
          action: :join,
          final: {
            'output' => [
              { 'x' => 1, 'y' => 2, 'z' => 1, 'a' => 1 },
              # row reproduced due to two matches in the joining table
              { 'x' => 2, 'y' => 2, 'z' => 2, 'a' => 4, 'q' => 2, 'p' => 2, 'r' => 1 },
              { 'x' => 2, 'y' => 2, 'z' => 2, 'a' => 4, 'q' => 2, 'p' => 3, 'r' => 2},
              { 'x' => 1, 'y' => 1, 'z' => 3, 'a' => 9 },
              { 'x' => 3, 'y' => 3, 'z' => 4, 'a' => 16 },
            ],
          },
        },
        {
          tables: ['bar', 'baz'],
          relation:  [['a'], ['p']],
          action: :inclusion,
          final: {
            'output' => [
              { 'a' => 1, 'b' => 1, 'c' => 5, 'is_member' => false, 'is_not_member' => true },
              { 'a' => 2, 'b' => 2, 'c' => 1, 'is_member' => true, 'is_not_member' => false },
            ],
          },
        },
        {
          tables: ['bar', 'baz'],
          relation:  [['a'], ['p']],
          action: :inclusion,
          include: { 'is_member' => 'bar' },
          final: {
            'output' => [
              { 'a' => 1, 'b' => 1, 'c' => 5, 'bar' => false },
              { 'a' => 2, 'b' => 2, 'c' => 1, 'bar' => true },
            ],
          },
        },
        {
          tables: ['bar', 'baz'],
          relation:  [['a'], ['p']],
          action: :inclusion,
          include: { 'is_not_member' => 'bar' },
          final: {
            'output' => [
              { 'a' => 1, 'b' => 1, 'c' => 5, 'bar' => true },
              { 'a' => 2, 'b' => 2, 'c' => 1, 'bar' => false },
            ],
          },
        },
      ]

      expected.each do |ex|
        r = XA::Rules::Rule.new

        ex[:tables].each { |n| r.push(n) }

        r.send(ex[:action]) do |act|
          act.using(*ex[:relation])
          act.include(ex[:include]) if ex.key?(:include)
        end

        r.commit('output')

        res = r.execute(XA::Rules::Context.new, tables.dup)
        expect(res[:tables]).to include(ex[:final])
      end
    end
 
    it 'should apply accumulation' do
      expected = [
        {
          table: 'foo',
          function: 'mult',
          args: ['x', 'y'],
          column: 'z',
          result: 'zm',
          values: [2.0, 8.0, 3.0, 36.0],
        },
        {
          table: 'bar',
          function: 'mult',
          args: ['b'],
          column: 'a',
          result: 'bm',
          values: [1.0, 4.0],
        },
        {
          table: 'strs',
          function: 'mult',
          args: ['q', 'p'],
          column: 'r',
          result: 'rm',
          values: [5.0, 14.0, 4.0],
        },
      ]

      expected.each do |ex|
        ctx = XA::Rules::Context.new
        r = XA::Rules::Rule.new
        r.push(ex[:table])
        r.accumulate(ex[:column], ex[:result]).apply(ex[:function], ex[:args])
        r.commit('results')
        res = r.execute(ctx, tables.dup)

        expect(res[:tables]).to have_key('results')
        tbl = res[:tables]['results']
        expect(tbl.map { |r| r[ex[:result]] }).to eql(ex[:values])
      end
    end
  end

  it 'should provide meta data about repositories' do
    expected = [
      { url: 'http://foo.com', name: 'foo' },
      { url: 'http://bar.com', name: 'baz' },
    ]

    r = XA::Rules::Rule.new
    expected.each do |ex|
      r.attach(ex[:url], ex[:name])
    end

    actual = []
    r.repositories do |url, name|
      actual << { url: url, name: name } 
    end
    
    expect(actual).to eql(expected)
  end

  it 'should pull outer tables via the context' do
    expected = [
      {
        ns: 'ns0',
        table: 'table0',
        version: '1',
        name: 'rt00',
        data: [
          { 'a' => '1', 'b' => '2' },
          { 'a' => '11', 'b' => '12' },
        ],
      },
      {
        ns: 'ns0',
        table: 'table1',
        version: '22',
        name: 'rt01',
        data: [
          { 'p' => '1', 'q' => '2' },
          { 'p' => '11', 'q' => '12' },
        ],
      },
      {
        ns: 'ns1',
        table: 'table11',
        version: 'latest',
        name: 'rt_latest',
        data: [
          { 'x' => 'zzz', 'y' => 'qqq' },
          { 'x' => 'aaa', 'y' => 'eee' },
        ],
      },
    ]

    ctx = XA::Rules::Context.new
    expected.each do |ex|
      r = XA::Rules::Rule.new
      r.pull(ex[:name], ex[:ns], ex[:table], ex[:version])
      r.push(ex[:name])
      r.commit('results')
      
      allow(ctx).to receive(:get).with(:table, { ns: ex[:ns], table: ex[:table], version: ex[:version] }).and_yield(ex[:data])
      res = ctx.execute(r)
      expect(res[:tables]['results']).to eql(ex[:data])
    end
  end

  it 'should optionally permit an audit that receives the state after each action' do
    class Audit
      attr_reader :runs
      
      def initialize
        @runs = {
          will: [],
          did: [],
        }
      end

      def will_run(name, env)
        @runs[:will] << { action: name, env: env }        
      end
      
      def ran(name, env)
        @runs[:did] << { action: name, env: env }
      end
    end

    r = XA::Rules::Rule.new
    r.pull('name', 'ns', 'table', 'ver')
    r.push('name')
    r.pop
    r.duplicate
    r.commit('name')

    audit = Audit.new
    ctx = XA::Rules::Context.new
    r.execute(ctx, {}, audit)

    names = [
      'pull', 'push', 'pop', 'duplicate', 'commit'
    ]
    expect(audit.runs[:will].map { |r| r[:action] }).to eql(names)
    expect(audit.runs[:will].select { |r| r[:env].empty? }).to eql([])
    expect(audit.runs[:did].map { |r| r[:action] }).to eql(names)
    expect(audit.runs[:did].select { |r| r[:env].empty? }).to eql([])
  end

  it 'should halt on error' do
    r = XA::Rules::Rule.new
    r.push('missing')

    res = r.execute(XA::Rules::Context.new, {})

    expect(res[:status]).to eql(:failure)
    expect(res[:failures]).to eql([{:reason=>"table_not_found", :details=>{:table=>"missing"}}])
  end
end
