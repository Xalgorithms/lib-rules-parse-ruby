require 'ostruct'
require 'xa/hash/deep'

describe XA::Rules::Interpreter do
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
  
  def make_document(depth)
    (0...rand(3) + 1).inject({}) do |doc, i|
      k = i.to_s

      0 == depth ? doc.merge(k => rand_leaf) : doc.merge(k => make_document(depth - 1))
    end
  end
  
  let(:documents) do
    rand_array { make_document(3) }
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

  def rand_documents
    rand_times.each do
      yield(rand_one(documents))
    end
  end
  
  it 'will generate changes for simple assignment' do
    rand_documents do |doc|
      keys = Set.new(rand_array { rand_key(doc) })

      expected = keys.inject({}) do |ex, k|
        randomly_happen do
          ex = ex.merge(k => rand_leaf)
        end
        ex
      end

      rule_opts = {
        mutations: expected.map { |k, v| { key: k, value: v } },
      }

      rule = XA::Rules::Rule.new(rule_opts)

      changes = interpreter.execute(doc, [rule]).first
      expected.each do |k, v|
        change = changes[k]
        expect(change.key).to eql(k)
        expect(change.original).to eql(doc.deep_fetch(k))
        expect(change.mutated).to eql(v)
      end
    end
  end

  it 'will generate changes for a referential assignment' do
    rand_documents do |doc|
      keys = Set.new(rand_array { rand_key(doc) })

      expected = keys.inject({}) do |ex, k|
        randomly_happen do
          ex = ex.merge(k => rand_key(doc))
        end
        
        ex
      end

      rule_opts = {
        using:     Set.new(expected.values).to_a,
        mutations: expected.map { |k, v| { key: k, value: "$#{v}" } }
      }

      rule = XA::Rules::Rule.new(rule_opts)

      changes = interpreter.execute(doc, [rule]).first
      expected.each do |k, v|
        change = changes[k]
        expect(change.key).to eql(k)
        expect(change.original).to eql(doc.deep_fetch(k))
        expect(change.mutated).to eql(doc.deep_fetch(v))
      end
    end
  end
end
