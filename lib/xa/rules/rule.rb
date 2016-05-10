require 'ostruct'

module XA
  module Rules
    class Rule
      attr_reader :meta

      def initialize
        @meta = OpenStruct.new(expects: [], commits: [])
        @actions = []
      end
      
      def expects(table_name, column_names)
        @meta.expects << OpenStruct.new(table: table_name, columns: column_names)
      end

      def use(table_name)
        add_action(Use.new(table_name))
      end

      def apply(table_name, active_cols, joint_cols)
        add_action(Apply.new(table_name, active_cols, joint_cols))
      end

      def duplicate(src_table_name, dst_table_name)
        add_action(Duplicate.new(src_table_name, dst_table_name))
      end

      def commit(table_name)
        @meta.commits << table_name
      end

      def execute(tables)
        res = verify_expectations(tables) do
          env = {
            active: nil,
            tables: tables,
          }
          
          @actions.each do |act|
            env = act.execute(env)
          end
          committed = env[:tables].select { |k, _| @meta.commits.include?(k) }
          OpenStruct.new(status: :ok, failures: [], tables: committed)
        end
      end

      private

      class Use
        def initialize(name)
          @name = name
        end

        def execute(env)
          env.merge(active: @name)
        end
      end

      class Apply
        FUNCTIONS = [:join, :replace]
        
        def initialize(name, active_cols, joint_cols)
          @name = name
          @active_cols = active_cols
          @joint_cols = joint_cols
          @applications = []
        end

        def using(fn, args)
          @funcs ||= FUNCTIONS.inject({}) do |o, n|
            o.merge(n => method("apply_#{n}"))
          end

          @applications << lambda do |left, right|
            @funcs.fetch(fn, method(:apply_nothing)).call(args, left, right)
          end
        end

        def apply_join(args, left, right)
          right = args.any? ? right.select { |k, _| args.include?(k) } : right
          left.merge(right)
        end

        def apply_replace(args, left, right)
          args.inject(left) do |o, k|
            o.key?(k) && right.key?(k) ? o.merge(k => right[k]) : o
          end
        end

        def apply_nothing(args, left, right)
          left
        end
        
        def execute(env)
          active_table = env[:tables].fetch(env[:active], [])
          joining_table = env[:tables].fetch(@name, [])

          final_table = active_table.inject([]) do |table, active_row|
            active_vals = @active_cols.map { |k| active_row.fetch(k, nil) }
            matching_rows = joining_table.select do |joining_row|
              active_vals == @joint_cols.map { |k| joining_row.fetch(k, nil) }
            end

            table + execute_applications(matching_rows, active_row)
          end

          env[:tables][env[:active]] = final_table
          env
        end

        private

        def execute_applications(matching_rows, existing_row)
          if matching_rows.any?
            matching_rows.map do |r|
              @applications.each do |fn|
                existing_row = fn.call(existing_row, r)
              end
              
              existing_row
            end
          else
            [existing_row]
          end
        end
      end

      class Duplicate
        def initialize(src, dst)
          @src = src
          @dst = dst
        end

        def execute(env)
          env[:tables] = env[:tables].merge(@dst => env[:tables][@src])
          env
        end
      end

      def add_action(act)
        @actions << act
        @actions.last
      end
      
      def verify_expectations(tables)
        missing = @meta.expects.select { |ex| !tables.key?(ex.table) }.map { |ex| ex.table }
        if missing.empty?
          yield
        else
          OpenStruct.new(status: :missing_expected_table, failures: missing)
        end
      end
    end
  end
end
