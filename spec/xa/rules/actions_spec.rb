require 'xa/rules/context'
require 'xa/rules/rule'

describe 'actions' do
  describe XA::Rules::Rule::Pull do
    it 'should get a table via the context' do
      rand_array_of_tables.each do |ntable|
        args = { ns: Faker::Lorem.word, table: Faker::Lorem.word, version: Faker::Number.hexadecimal(6) }

        ctx = XA::Rules::Context.new
        allow(ctx).to receive(:get).with(:table, args).and_yield(ntable)
        env = {
          ctx: ctx,
          tables: {},
          stack: [],
        }
        
        act = XA::Rules::Rule::Pull.new(args[:table], args[:ns], args[:table], args[:version])

        nenv = act.execute(env, nil)
        expect(nenv[:tables]).to include(args[:table] => ntable)
      end
    end
  end

  describe XA::Rules::Rule::Push do
    it 'should put a named table on the stack' do
      tables = rand_hash_of_tables
      ctx = XA::Rules::Context.new
      env = { ctx: ctx, tables: tables, stack: [] }

      oenv = env
      tables.each do |name, tbl|
        act = XA::Rules::Rule::Push.new(name)
        ostack = oenv[:stack]
        nenv = act.execute(oenv, nil)
        expect(oenv[:stack]).to eql(ostack)
        expect(nenv[:stack]).to eql(ostack << tbl)
      end
    end
  end

  describe XA::Rules::Rule::Pop do
    it 'should remove the top of the stack' do
      ctx = XA::Rules::Context.new
      tables = rand_array_of_tables
      env = { ctx: ctx, tables: {}, stack: tables }

      oenv = env
      tables.each do |_, _|
        act = XA::Rules::Rule::Pop.new
        ostack = oenv[:stack]
        nenv = act.execute(oenv, nil)
        expect(oenv[:stack]).to eql(ostack)
        expect(nenv[:stack]).to eql(ostack[0...-1])
      end
    end

    it 'should handle an empty stack' do
      ctx = XA::Rules::Context.new
      env = { ctx: ctx, tables: {}, stack: [] }

      rand_times.each do |_, _|
        act = XA::Rules::Rule::Pop.new
        nenv = act.execute(env, nil)
        expect(nenv[:stack]).to be_empty
      end
    end
  end

  describe XA::Rules::Rule::Duplicate do
    it 'should duplicate the top of the stack' do
      ctx = XA::Rules::Context.new
      tbl = rand_table
      env = { ctx: ctx, tables: {}, stack: [tbl] }

      oenv = env
      rand_times.each do
        act = XA::Rules::Rule::Duplicate.new
        ostack = oenv[:stack]
        nenv = act.execute(oenv, nil)
        expect(oenv[:stack]).to eql(ostack)
        expect(nenv[:stack]).to eql(ostack << tbl)
      end
    end
    
    it 'should handle an empty stack' do
      ctx = XA::Rules::Context.new
      env = { ctx: ctx, tables: {}, stack: [] }
      
      rand_times.each do
        act = XA::Rules::Rule::Duplicate.new
        nenv = act.execute(env, nil)
        expect(nenv[:stack]).to be_empty
      end
    end
  end

  describe XA::Rules::Rule::Commit do
    it 'should remove the top of the stack in the results' do
      ctx = XA::Rules::Context.new
      tables = rand_array_of_tables
      env = { ctx: ctx, tables: {}, stack: tables }

      oenv = env
      tables.reverse.each do |tbl|
        name = Faker::Number.hexadecimal(10)
        act = XA::Rules::Rule::Commit.new(name)
        res = OpenStruct.new(tables: {})
        ostack = oenv[:stack]
        nenv = act.execute(oenv, res)
        expect(oenv[:stack]).to eql(ostack)
        expect(nenv[:stack]).to eql(ostack[0...-1])
        expect(res.tables[name]).to eql(tbl)
        oenv = nenv
      end
    end

    it 'should remove the top of the stack in the results with column selection' do
      ctx = XA::Rules::Context.new
      tables = rand_array_of_tables
      env = { ctx: ctx, tables: {}, stack: tables }

      oenv = env
      tables.reverse.each do |tbl|
        cols = rand_some(tbl.first.keys)
        ex_tbl = tbl.map do |r|
          cols.inject({}) { |o, k| o.merge(k => r[k]) }
        end
        name = Faker::Lorem.word
        act = XA::Rules::Rule::Commit.new(name, cols)
        res = OpenStruct.new(tables: {})
        ostack = oenv[:stack]
        nenv = act.execute(oenv, res)
        expect(oenv[:stack]).to eql(ostack)
        expect(nenv[:stack]).to eql(ostack[0...-1])
        expect(res.tables).to include(name => ex_tbl)
        oenv = nenv
      end
    end

    it 'should handle an empty stack' do
      ctx = XA::Rules::Context.new
      tables = rand_array_of_tables
      env = { ctx: ctx, tables: {}, stack: [] }

      oenv = env
      tables.reverse.each do |tbl|
        name = Faker::Lorem.word
        act = XA::Rules::Rule::Commit.new(name)
        res = OpenStruct.new(tables: {})
        nenv = act.execute(oenv, res)
        expect(nenv[:stack]).to be_empty
        expect(res.tables).to be_empty
      end
    end
  end

  describe XA::Rules::Rule::Join do
    it 'should join two tables' do
      left_tbl = [
        { a: 1, b: 2, c: 3 },
        { a: 2, b: 4, c: 8 },
        { a: 3, b: 9, c: 27 },
      ]

      right_tbl = [
        { a: 1, x: 1 },
        { a: 2, x: 1 },
      ]

      ex_tbl = [
        { a: 1, x: 1, b: 2, c: 3 },
        { a: 2, x: 1, b: 4, c: 8 },        
        { a: 3, b: 9, c: 27 },
      ]

      ctx = XA::Rules::Context.new
      tables = rand_array_of_tables
      env = { ctx: ctx, tables: {}, stack: [left_tbl, right_tbl] }
      act = XA::Rules::Rule::Join.new
      act.using([:a], [:a])

      oenv = env
      nenv = act.execute(oenv, nil)
      expect(oenv).to eql(env)
      expect(nenv[:stack]).to eql([ex_tbl])
    end

    it 'should join two tables, only including specific columns' do
      left_tbl = [
        { a: 1, b: 2, c: 3 },
        { a: 2, b: 4, c: 8 },
        { a: 3, b: 9, c: 27 },
      ]

      right_tbl = [
        { a: 1, x: 1, y: 11 },
        { a: 2, x: 2, y: 22 },
      ]

      ex_tbl = [
        { a: 1, aa: 1, xx: 1, b: 2, c: 3 },
        { a: 2, aa: 2, xx: 2, b: 4, c: 8 },        
        { a: 3, b: 9, c: 27 },
      ]

      ctx = XA::Rules::Context.new
      env = { ctx: ctx, tables: {}, stack: [left_tbl, right_tbl] }
      act = XA::Rules::Rule::Join.new
      act.using([:a], [:a])
      act.include(a: :aa, x: :xx)

      oenv = env
      nenv = act.execute(oenv, nil)
      expect(oenv).to eql(env)
      expect(nenv[:stack]).to eql([ex_tbl])
    end

    it 'should handle starved stack' do
      ctx = XA::Rules::Context.new
      env = { ctx: ctx, tables: {}, stack: [] }
      act = XA::Rules::Rule::Join.new
      act.using([:a], [:a])
      act.include(a: :aa, x: :xx)

      nenv = act.execute(env, nil)
      expect(nenv).to eql(env)

      env = { ctx: ctx, tables: {}, stack: [{}] }
      nenv = act.execute(env, nil)
      expect(nenv).to eql(env)
    end

    it 'should not affect left keys' do
      left_tbl = [
        { a: 1, b: 2, c: 3 },
        { a: 2, b: 4, c: 8 },
        { a: 3, b: 9, c: 27 },
      ]

      right_tbl = [
        { a: 1, x: 1, y: 11 },
        { a: 2, x: 2, y: 22 },
      ]

      ex_tbl = [
        { a: 1, xx: 1, b: 2, c: 3 },
        { a: 2, xx: 2, b: 4, c: 8 },        
        { a: 3, b: 9, c: 27 },
      ]

      ctx = XA::Rules::Context.new
      env = { ctx: ctx, tables: {}, stack: [left_tbl, right_tbl] }
      act = XA::Rules::Rule::Join.new
      act.using([:a], [:a])
      act.include(b: :bb, x: :xx)

      oenv = env
      nenv = act.execute(oenv, nil)
      expect(oenv).to eql(env)
      expect(nenv[:stack]).to eql([ex_tbl])
    end
  end

  describe XA::Rules::Rule::Accumulate do
    it 'should accumlate multiplication' do
      tbl = [
        { a: 2, b: 3, c: 4, d: 100 },
        { a: 3, b: 4, c: 5, d: 200 },
        { a: 4, b: 5, c: 6, d: 300 },
      ]

      ex_tbl = [
        { acc: 24.0, a: 2, b: 3, c: 4, d: 100 },
        { acc: 60.0, a: 3, b: 4, c: 5, d: 200 },
        { acc: 120.0, a: 4, b: 5, c: 6, d: 300 },
      ]

      ctx = XA::Rules::Context.new
      env = { ctx: ctx, tables: {}, stack: [tbl] }
      act = XA::Rules::Rule::Accumulate.new(:a, :acc)
      act.apply('mult', [:b, :c])

      oenv = env
      nenv = act.execute(oenv, nil)
      expect(oenv).to eql(env)
      expect(nenv[:stack]).to eql([ex_tbl])      
    end

    it 'can handle stack starvation' do
      ctx = XA::Rules::Context.new
      env = { ctx: ctx, tables: {}, stack: [] }
      act = XA::Rules::Rule::Accumulate.new(:a, :acc)
      act.apply('mult', [:b, :c])

      nenv = act.execute(env, nil)
      expect(nenv).to eql(env)
    end
  end
end
