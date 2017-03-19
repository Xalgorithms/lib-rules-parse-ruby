require 'xa/rules/context'
require 'xa/rules/rule'
require 'xa/registry/client'

describe XA::Rules::Context do
  it 'should execute a rule, in context' do
    r = instance_double(XA::Rules::Rule)
    cl = instance_double(XA::Registry::Client)

    ctx = XA::Rules::Context.new

    expect(r).to receive(:execute).with(ctx, {})
    expect(r).to receive(:repositories).and_yield(nil, nil)

    expect(XA::Registry::Client).to receive(:new).and_return(cl)
    expect(cl).to receive(:namespaces).and_return([])
    
    ctx.execute(r)
  end

  it 'should provide tables to the rule' do
    tables = { foo: [], bar: [] }
    ctx = XA::Rules::Context.new(tables)

    rule = instance_double(XA::Rules::Rule)
    expect(rule).to receive(:repositories).and_return({})
    expect(rule).to receive(:execute).with(ctx, tables)

    ctx.execute(rule)
  end
  
  it 'should download from the registry' do
    expectations = [
      {
        url: 'http://foo.com',
        repo: 'foo',
        ns: 'foons',
        table: 'table_foo',
        version: '1234',
        type: :table,
        data: [
          { 'a' => '1', 'b' => '2' },
          { 'a' => '11', 'b' => '12' },
        ],
      },
      {
        url: 'http://faa.com',
        repo: 'baz',
        ns: 'bazns',
        table: 'table_baz',
        version: '111',
        type: :table,
        data: [
          { 'p' => '1', 'q' => '2' },
          { 'p' => '11', 'q' => '12' },
        ],
      },
      {
        url: 'http://faa.com',
        repo: 'baz1',
        ns: 'xalgo',
        rule: 'rule_x',
        version: '111',
        type: :rule,
        data: {
          actions: [],
        }
      },
    ]

    # context should be reusable
    ctx = XA::Rules::Context.new
    
    expectations.each do |ex|
      r = XA::Rules::Rule.new
      r.attach(ex[:url], ex[:repo])

      cl = instance_double(XA::Registry::Client)
      expect(cl).to receive(:namespaces).and_return([ex[:ns]])
                                                    
      expect(XA::Registry::Client).to receive(:new).with(ex[:url]).and_return(cl)
      ctx.execute(r)

      if ex.key?(:table)
        expect(cl).to receive(:tables).with(ex[:ns], ex[:table], ex[:version]).and_return(ex[:data])
        ctx.get(ex[:type], { repo: ex[:repo], ns: ex[:ns], table: ex[:table], version: ex[:version] }) do |actual|
          expect(actual).to eql(ex[:data])
        end
      elsif ex.key?(:rule)
        expect(cl).to receive(:rule_by_reference).with(ex[:ns], ex[:rule], ex[:version]).and_return(ex[:data])
        ctx.get(ex[:type], { repo: ex[:repo], ns: ex[:ns], rule: ex[:rule], version: ex[:version] }) do |actual|
          expect(actual).to eql(ex[:data])
        end
      end
    end
  end

  it 'should communicate execution errors' do
    ctx = XA::Rules::Context.new
    r = XA::Rules::Rule.new

    expect(r).to receive(:execute).and_return({ status: :failure, failures: [{:reason=>"table_not_found", :details=>{:table=>"missing"}}]})

    res = ctx.execute(r)

    expect(res[:status]).to eql(:failure)
    expect(res[:failures]).to eql([{:reason=>"table_not_found", :details=>{:table=>"missing"}}])    
  end
end
