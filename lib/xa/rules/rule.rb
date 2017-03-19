require 'ostruct'
require_relative './errors'

module XA
  module Rules
    class Rule
      attr_reader :meta

      def initialize
        @meta = OpenStruct.new(expects: [], repos: {})
        @actions = []
      end

      def expects(table_name, column_names)
        @meta.expects << OpenStruct.new(table: table_name, columns: column_names)
      end

      def attach(url, name)
        @meta.repos[name] = url
      end

      def repositories
        @meta.repos.each do |k, v|
          yield(v, k)
        end
      end

      def pull(name, ns, table, version)
        add(Pull.new(name, ns, table, version))
      end

      def push(n)
        add(Push.new(n))
      end

      def pop
        add(Pop.new)
      end

      def duplicate
        add(Duplicate.new)
      end

      def commit(name, columns = nil)
        add(Commit.new(name, columns))
      end

      def join(&bl)
        act = add(Join.new, &bl)
      end

      def inclusion(&bl)
        act = add(Inclusion.new, &bl)
      end

      def accumulate(column, result, &bl)
        act = add(Accumulate.new(column, result), &bl)
      end

      def execute(ctx, tables, audit = nil)
        verify_expectations(tables) do |res|
          env = {
            ctx: ctx,
            tables: tables,
            stack: [],
          }
          fenv = @actions.inject({ tables: {} }) do |o, act|
            # p stack
            name = act.class.name.split('::').last.downcase
            audit.will_run(name, env) if audit
            env = act.execute(env)
            audit.ran(name, env) if audit
            o.merge(env)
          end

          errs = fenv.fetch(:errors, [])
          res.merge(status: errs.empty? ? :ok : :failure, failures: errs, tables: res[:tables].merge(fenv[:tables]))
        end
      end

      class Action
        def make_env(env={})
          env.clone
        end

        def execute(env)
          act(make_env(env))
        end

        def add_error(env, reason, details=nil)
          err = { reason: reason }
          err = err.merge(details: details) if details
          env.merge(errors: env.fetch(:errors, []) + [err])
        end
      end
      
      class Pull < Action
        def initialize(name, ns, table, version)
          @name = name
          @args = { ns: ns, table: table, version: version }
        end

        def act(env)
          if env[:ctx]
            env[:ctx].logger.info("pulling from context (args=#{@args})")
            env[:ctx].get(:table, @args) do |tbl|
              if tbl
                env[:tables] = env[:tables].merge(@name => tbl)
              else
                env = add_error(env, XA::Rules::Errors::TABLE_NOT_FOUND, @args)
              end
            end

            env
          end
        end
      end
      
      class Push < Action
        def initialize(n)
          @name = n
        end

        def act(env)
          env[:ctx].logger.debug("push (name=#{@name}; tables=#{env[:tables].keys.join('|')})") if env[:ctx]
          # bit esoteric to avoid side-effects
          if env[:tables].key?(@name)
            env.merge(stack: env[:stack] + [env[:tables][@name]])
          else
            add_error(env, XA::Rules::Errors::TABLE_NOT_FOUND, { table: @name })
          end
        end
      end

      class Pop < Action
        def act(env)
          env[:ctx].logger.debug("pop (tables=#{env[:tables].keys.join('|')})") if env[:ctx]
          if !env[:stack].empty?
            env.merge(stack: env[:stack][0...-1])
          else
            add_error(env, XA::Rules::Errors::STACK_EMPTY)
          end
        end
      end

      class Duplicate < Action
        def act(env)
          # bit esoteric to avoid side-effects
          if !env[:stack].empty?
            env.merge(stack: env[:stack] + [env[:stack].last.dup])
          else
            add_error(env, XA::Rules::Errors::STACK_EMPTY)
          end
        end
      end

      class Commit < Action
        def initialize(name, columns=nil)
          @name = name
          @columns = columns
        end

        def act(env)
          if env[:stack].any?
            t = env[:stack].last
            env[:ctx].logger.info("committing (table=#{t}; name=#{@name}; cols=#{@columns})") if env[:ctx]
            t = t.map { |r| r.select { |k, _| @columns.include?(k) } } if @columns
            env.merge(stack: env[:stack][0...-1], tables: env[:tables].merge(@name => t))
          else
            env[:ctx].logger.warn('nothing on the stack to commit') if env[:ctx]
            add_error(env, XA::Rules::Errors::STACK_EMPTY)
          end
        end
      end

      class Join < Action
        def using(lefts, rights)
          @joint = { left: lefts, right: rights }
          self
        end

        def include(includes)
          @includes = includes
          self
        end

        def act(env)
          right = env[:stack][-1]
          left = env[:stack][-2]

          if right && left
            env[:ctx].logger.info("join (right=#{right}; left=#{left})") if env[:ctx]
            
            table = left.inject([]) do |table, lr|
              lvals = @joint[:left].map { |k| lr.fetch(k, nil) }
              matches = right.select do |rr|
                lvals == @joint[:right].map { |k| rr.fetch(k, nil) }
              end

              table + resolve(matches, lr)
            end

            env[:ctx].logger.info("joined (table=#{table})") if env[:ctx]

            env.merge(stack: env[:stack][0...-2] << table)
          else
            add_error(env, XA::Rules::Errors::STACK_STARVED)            
          end
        end

        private

        def resolve(matching_rows, existing_row)
          if matching_rows.any?
            matching_rows.map do |r|
              resolve_row(existing_row, r)
            end
          else
            [existing_row]
          end
        end

        def resolve_row(left, right)
          right = right.select do |k, _|
            @includes.key?(k)
          end.inject({}) do |o, kv|
            o.merge(@includes[kv.first] => kv.last)
          end if @includes

          left.merge(right)
        end
      end

      class Inclusion < Join
        def initialize
          @includes = { 'is_not_member' => 'is_not_member', 'is_member' => 'is_member' }
        end
        
        def resolve(matching_rows, existing_row)
          o = { }.tap do |o|
            o[@includes['is_member']] = matching_rows.any? if @includes.key?('is_member')
            o[@includes['is_not_member']] = matching_rows.empty? if @includes.key?('is_not_member')
          end

          [existing_row.merge(o)]
        end
      end

      class Accumulate < Action
        class Func
          def initialize(args)
            @args = args
          end

          def apply_to_row(row, start)
            apply([start] + @args.map { |arg| row.fetch(arg, nil) })
          end
        end
        
        class Mult < Func
          def apply(vals)
            vals.map { |v| v ? v.to_f : 1.0 }.inject(1) { |total, v| total * v }
          end
        end

        def initialize(column, result)
          @column = column
          @result = result
          @applications = []
          @functions = {
            'mult' => Mult,
          }
          @invalid_applications = []
        end

        def apply(func, args)
          if @functions.key?(func)
            @applications << @functions[func].new(args)
          else
            @invalid_applications << func
          end
        end

        def act(env)
          tbl = env[:stack][-1]
          if tbl && !@applications.empty?
            env[:ctx].logger.info("accumulating (tbl=#{tbl})") if env[:ctx]
            res = tbl.map do |r|
              r.merge(@result => @applications.first.apply_to_row(r, r.fetch(@column, nil)))
            end
            env[:ctx].logger.info("accumulated (res=#{res})") if env[:ctx]
            env.merge(stack: env[:stack][0...-1] << res)
          elsif @applications.empty?
            add_error(env, XA::Rules::Errors::NO_VALID_APPLICATIONS, { functions: @invalid_applications })
          else
            add_error(env, XA::Rules::Errors::STACK_STARVED)            
          end
        end
      end
      
      private

      def add(act, &bl)
        @actions << act
        bl.call(act) if bl
        act
      end
      
      def verify_expectations(tables)
        missing = @meta.expects.select { |ex| !tables.key?(ex.table) }.map { |ex| ex.table }
        if missing.empty?
          yield({ status: :ok, failures: [], tables: {} })
        else
          { status: :failure, failures: [{ reason: :missing_expected_table, details: missing }] }
        end
      end
    end
  end
end
