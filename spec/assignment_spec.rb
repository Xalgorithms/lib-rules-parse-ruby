require 'ostruct'

describe 'assignment' do
  let(:leaves) do
    [
      lambda { Faker::Number.number(4).to_i },
      lambda { Faker::Number.decimal(4).to_f },
      lambda { Faker::Lorem.word },
    ]
  end

  def rand_leaf
    rand_one(leaves).call    
  end
  
  let(:document) do
    rand_array(&Faker::Lorem.method(:word)).inject({}) do |o, w|
      doc = randomly_happen { rand_leaf }
      doc = document unless doc

      o.merge(w => doc)
    end
  end
  
  let(:documents) do
    rand_array(&method(:document))
  end

  let(:interpreter) do
    XA::Rules::Interpreter.new
  end
  
  def rand_key(h)
    if h.class == Hash
      k = rand_one(h.keys)
      randomly_happen do
        k = [k, rand_key(h.fetch(k))].compact.join('.')
      end
      k
    end
  end

  def do_deep_fetch(h, keys)
    if keys.length == 1
      h.fetch(keys.first, nil)
    else
      do_deep_fetch(h.fetch(keys.first, {}), keys[1..-1])
    end
  end
  
  def deep_fetch(h, k)
    do_deep_fetch(h, k.split('.'))
  end
  
  it 'will mutate fields using constants' do
    rand_times.each do
      doc = rand_one(documents)
      keys = Set.new(rand_array { rand_key(doc) })

      expected = keys.inject({}) do |ex, k|
        randomly_happen do
          ex = ex.merge(k => rand_leaf)
        end
        ex
      end

      rule_opts = {
        # NOTE to SELF: using is for variables, maybe ... OR it's a restriction on what can be mutated
        # using:     keys.to_a,
        mutations: [],
      }.tap do |r|
        expected.each do |k, v|
          mutation = {
            key:      k,
            value:    v,
          }
          
          r[:mutations] = r[:mutations] + [mutation]
        end
      end

      rule = XA::Rules::Rule.new(rule_opts)
      
      changes = interpreter.execute(doc, [rule]).first
      expected.each do |k, v|
        change = changes[k]
        expect(change.original).to eql(deep_fetch(doc, k))
        expect(change.mutated).to eql(v)
      end
    end
  end
end
