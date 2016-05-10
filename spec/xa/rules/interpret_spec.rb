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

  it 'will configure commands' do
    o = {
      'commands' => [
        {
          'type'     => 'apply',
          'function' => { 'name' => 'join', 'args' => ['a','b'] },
          'args'     => {
            'left'  => ['a', 'b'],
            'right' => ['f', 'g'],
          },
        },
        {
          'type'  => 'apply',
          'function' => { 'name' => 'replace', 'args' => ['a'] },
          'args'  => {
            'left'  => ['qq', 'pp'],
            'right' => ['zz', 'yy'],
          },
        },
      ],
    }

    with_rule(o) do
      o['commands'].each do |c|
        send("expect_#{c['type']}", c, rule)
      end
    end
  end

  def expect_apply(c, r)
    o = double(:apply)
    expect(o).to receive(:using).with(c['args']['left'], c['args']['right'])
    expect(r).to receive(:apply).with(c['function']['name'], c['function']['args']).and_return(o)
  end
end
