require 'xa/rules/interpret'
require 'xa/rules/rule'

describe XA::Rules::Interpret do
  let(:rule) do
    instance_double(XA::Rules::Rule)
  end

  include XA::Rules::Interpret

  def with_rule(o)
    expect(XA::Rules::Rule).to receive(:new).and_return(rule)
    yield
    interpret(o)
  end
  
  it 'will configure expects' do
    o = {
      'meta' => {
        'expects' => {
          'foo' => ['z', 'zz'],
          'bar' => ['a', 'b'],
        },
      },
    }

    with_rule(o) do
      o['meta']['expects'].each do |tn, cols|
        expect(rule).to receive(:expects).with(tn, cols)
      end
    end
  end

  it 'will configure actions' do
    o = {
      'actions' => [
        {
          'name'     => 'join',
          'using'    => {
            'left'  => ['a', 'b'],
            'right' => ['f', 'g'],
          },
          'include' => { 'a' => 'aa', 'b' => 'bb' }
        },
        {
          'name'     => 'inclusion',
          'using'    => {
            'left'  => ['a', 'b'],
            'right' => ['f', 'g'],
          },
          'include' => { 'a' => 'aa', 'b' => 'bb' }
        },
        {
          'name'  => 'commit',
          'table' => 'a',
        },
        {
          'name'  => 'commit',
          'table' => 'a',
          'columns' => ['x', 'y'],
        },
        {
          'name' => 'push',
          'table' => 'foo',
        },
        {
          'name' => 'push',
          'table' => 'bar',
        },
        {
          'name' => 'pop',
        },
        {
          'name' => 'duplicate',
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
      ],
    }

    with_rule(o) do
      o['actions'].each do |act|
        send("expect_#{act['name']}", act, rule)
      end
    end
  end

  def expect_commit(c, r)
    expect(r).to receive(:commit).with(c['table'], c.fetch('columns', nil))
  end
  
  def expect_inclusion(c, r)
    expect_joinish(:inclusion, c, r)
  end
  
  def expect_join(c, r)
    expect_joinish(:join, c, r)
  end

  def expect_push(c, r)
    expect(r).to receive(:push).with(c['table'])
  end
  
  def expect_pop(c, r)
    expect(r).to receive(:pop)
  end
  
  def expect_duplicate(c, r)
    expect(r).to receive(:duplicate)
  end
  
  def expect_joinish(action, c, r)
    o = double(action)
    expect(r).to receive(action).and_return(o)
    expect(o).to receive(:using).with(c['using']['left'], c['using']['right']).and_return(o)
    expect(o).to receive(:include).with(c['include']).and_return(o)
  end

  def expect_accumulate(c, r)
    o = double(:accumulate)
    expect(r).to receive(:accumulate).with(c['column'], c.fetch('result', nil)).and_return(o)
    expect(o).to receive(:apply).with(c['function']['name'], c['function']['args'])
  end
end
