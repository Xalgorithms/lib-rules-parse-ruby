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
        def initialize(name, active_cols, joint_cols)
          @name = name
          @active_cols = active_cols
          @joint_cols = joint_cols
        end

        def using(fn, args)
        end

        def execute(env)
          atbl = env[:tables].fetch(env[:active], [])
          jtbl = env[:tables].fetch(@name, [])
          ftbl = atbl.inject([]) do |a, ar|
            avals = @active_cols.map { |k| ar.fetch(k, nil) }
            jrows = jtbl.select { |jr| avals == @joint_cols.map { |k| jr.fetch(k, nil) } }
            a + (jrows.any? ? jrows.map { |jr| ar.merge(jr) } : [ar])
          end

          env[:tables][env[:active]] = ftbl
          env
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
