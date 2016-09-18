require 'ostruct'

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

      def execute(ctx, tables)
        res = verify_expectations(tables) do |res|
          stack = []
          @actions.each do |act|
            # p stack
            act.execute(ctx, tables, stack, res)
          end

          res
        end
      end

      private

      class Pull
        def initialize(name, ns, table, version)
          @name = name
          @args = { ns: ns, table: table, version: version }
        end

        def execute(ctx, tables, stack, res)
          ctx.logger.info("pulling from context (args=#{@args})") if ctx
          ctx.get(:table, @args) do |tbl|
            tables[@name] = tbl
          end if !tables.key?(@name)
        end
      end
      
      class Push
        def initialize(n)
          @name = n
        end

        def execute(ctx, tables, stack, res)
          ctx.logger.debug("push (name=#{@name}; tables=#{tables.keys.join('|')})") if ctx
          stack.push(tables[@name])
        end
      end

      class Pop
        def execute(ctx, tables, stack, res)
          stack.pop
        end
      end

      class Duplicate
        def execute(ctx, tables, stack, res)
          stack.push(stack.last.dup)
        end
      end

      class Commit
        def initialize(name, columns)
          @name = name
          @columns = columns
        end

        def execute(ctx, tables, stack, res)
          if stack.any?
            t = stack.pop
            t = t.map { |r| r.select { |k, _| @columns.include?(k) } } if @columns
            res.tables = res.tables.merge(@name => t)
          end
        end
      end

      class Join
        def using(lefts, rights)
          @joint = { left: lefts, right: rights }
          self
        end

        def include(includes)
          @includes = includes
          self
        end

        def execute(ctx, tables, stack, res)
          right = stack.pop
          left = stack.pop

          ctx.logger.info("join (right=#{right}; left=#{left})") if ctx
          
          table = left.inject([]) do |table, lr|
            lvals = @joint[:left].map { |k| lr.fetch(k, nil) }
            matches = right.select do |rr|
              lvals == @joint[:right].map { |k| rr.fetch(k, nil) }
            end

            table + resolve(matches, lr)
          end

          stack.push(table)
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
          o = {
          }.tap do |o|
            o[@includes['is_member']] = matching_rows.any? if @includes.key?('is_member')
            o[@includes['is_not_member']] = matching_rows.empty? if @includes.key?('is_not_member')
          end

          [existing_row.merge(o)]
        end
      end

      class Accumulate
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

        class Empty < Func
          def apply(vals)
            vals
          end
        end
        
        def initialize(column, result)
          @column = column
          @result = result
          @applications = []
        end

        def apply(func, args)
          @functions ||= {
            'mult' => Mult,
          }

          @applications << @functions.fetch(func, Empty).new(args)
          @applications.last
        end

        def execute(ctx, tables, stack, res)
          tbl = stack.pop
          stack.push(tbl.map do |r|
            r.merge(@result => @applications.first.apply_to_row(r, r.fetch(@column, nil)))
          end)
        end
      end
      
      def add(act, &bl)
        @actions << act
        bl.call(act) if bl
        act
      end
      
      def verify_expectations(tables)
        missing = @meta.expects.select { |ex| !tables.key?(ex.table) }.map { |ex| ex.table }
        if missing.empty?
          yield(OpenStruct.new(status: :ok, failures: [], tables: {}))
        else
          OpenStruct.new(status: :missing_expected_table, failures: missing)
        end
      end
    end
  end
end
