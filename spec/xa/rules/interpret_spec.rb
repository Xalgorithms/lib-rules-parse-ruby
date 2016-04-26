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
      'expects' => {
        'foo' => ['z', 'zz'],
        'bar' => ['a', 'b'],
      },
    }

    with_rule(o) do
      o['expects'].each do |tn, cols|
        expect(rule).to receive(:expects).with(tn, cols)
      end
    end
  end

  it 'will configure commands' do
    o = {
      'commands' => [
        ['use', 'foo'],
        ['use', 'bar'],
        ['apply', 'foo', ['a', 'b'], ['f', 'g']],
        ['apply', 'bar', ['x', 'y'], ['h', 'i']],
      ],
    }

    with_rule(o) do
      o['commands'].each do |c|
        expect(rule).to receive(c.first.to_sym).with(*c[1..-1])
      end
    end
  end
end
