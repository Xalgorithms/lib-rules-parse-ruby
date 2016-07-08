require 'xa/rules/context'
require 'xa/rules/rule'
require 'xa/repository/client'

describe XA::Rules::Context do
  it 'should execute a rule, in context' do
    r = instance_double(XA::Rules::Rule)
    ctx = XA::Rules::Context.new

    expect(r).to receive(:execute).with(ctx, {})
    expect(r).to receive(:repositories).and_yield(nil, nil)
    ctx.execute(r)
  end

  it 'should download from the repository' do
    expectations = [
      {
        url: 'http://foo.com',
        repo: 'foo',
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
        table: 'table_baz',
        version: '111',
        type: :table,
        data: [
          { 'p' => '1', 'q' => '2' },
          { 'p' => '11', 'q' => '12' },
        ],
      },
    ]

    # context should be reusable
    ctx = XA::Rules::Context.new
    
    expectations.each do |ex|
      r = XA::Rules::Rule.new
      r.attach(ex[:url], ex[:repo])

      cl = instance_double(XA::Repository::Client)
      expect(XA::Repository::Client).to receive(:new).with(ex[:url]).and_return(cl)
      ctx.execute(r)

      expect(cl).to receive(:tables).with(ex[:table], ex[:version]).and_return(ex[:data])
      ctx.get(ex[:type], { repo: ex[:repo], table: ex[:table], version: ex[:version] }) do |actual|
        expect(actual).to eql(ex[:data])
      end
    end
  end
end
