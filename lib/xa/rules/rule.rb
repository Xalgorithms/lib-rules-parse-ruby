require 'ostruct'

module XA
  module Rules
    class Rule
      attr_reader :meta

      def initialize
        @meta = OpenStruct.new(expects: [])
        @actions = []
      end
      
      def expects(table_name, column_names)
        @meta.expects << OpenStruct.new(table: table_name, columns: column_names)
      end

      def push(n)
        add(Push.new(n))
      end

      def duplicate
        add(Duplicate.new)
      end

      def store(name)
        add(Store.new(name))
      end

      def commit(names)
        add(Commit.new(names))
      end

      def apply(func, args)
        add(Apply.new(func, args))
      end
      
      def execute(tables)
        res = verify_expectations(tables) do |res|
          stack = []
          @actions.each do |act|
            act.execute(tables, stack, res)
          end

          res
        end
      end

      private

      class Push
        def initialize(n)
          @name = n
        end

        def execute(tables, stack, res)
          stack.push(tables[@name])
        end
      end

      class Duplicate
        def execute(tables, stack, res)
          stack.push(stack.last.dup)
        end
      end

      class Store
        def initialize(n)
          @name = n
        end

        def execute(tables, stack, res)
          tables[@name] = stack.pop if stack.any?
        end
      end

      class Commit
        def initialize(names)
          @names = names
        end

        def execute(tables, stack, res)
          res.tables = @names.inject(res.tables) do |ts, name|
            tables.key?(name) ? ts.merge(name => tables[name]) : ts
          end
        end
      end
      
      class Apply
        FUNCTIONS = [:join, :replace]

        def initialize(func, args)
          @func = func
          @args = args
          @functions = FUNCTIONS.inject({}) do |o, n|
            o.merge(n => method("resolve_#{n}"))
          end
        end

        def using(lefts, rights)
          @joint = { left: lefts, right: rights }
        end
        
        def execute(tables, stack, res)
          right = stack.pop
          left = stack.pop

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
              fn = @functions.fetch(@func, method(:resolve_nothing))
              fn.call(@args, existing_row, r)
            end
          else
            [existing_row]
          end
        end

        def resolve_nothing(args, left, right)
          left
        end

        def resolve_join(args, left, right)
          right = args.any? ? right.select { |k, _| args.include?(k) } : right
          left.merge(right)
        end

        def resolve_replace(args, left, right)
          args.inject(left) do |o, k|
            o.key?(k) && right.key?(k) ? o.merge(k => right[k]) : o
          end
        end
      end

      def add(act)
        @actions << act
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
