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
      ],
    }

    with_rule(o) do
      o['actions'].each do |act|
        send("expect_#{act['name']}", act, rule)
      end
    end
  end

  def expect_join(c, r)
    o = double(:join)
    expect(r).to receive(:join).and_return(o)
    expect(o).to receive(:using).with(c['using']['left'], c['using']['right']).and_return(o)
    expect(o).to receive(:include).with(c['include']).and_return(o)
  end
end
