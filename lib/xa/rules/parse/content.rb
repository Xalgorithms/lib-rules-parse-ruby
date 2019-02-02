# Copyright (C) 2018 Don Kelly <karfai@gmail.com>
# Copyright (C) 2018 Hayk Pilosyan <hayk.pilos@gmail.com>

# This file is part of Interlibr, a functional component of an
# Internet of Rules (IoR).

# ACKNOWLEDGEMENTS
# Funds: Xalgorithms Foundation
# Collaborators: Don Kelly, Joseph Potvin and Bill Olders.

# This program is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public
# License along with this program. If not, see
# <http://www.gnu.org/licenses/>.

require_relative './rule_parser'
require_relative './table_parser'

module XA
  module Rules
    module Parse
      module Content
        def parse_rule(content)
          parse(XA::Rules::Parse::RuleParser, content)
        end

        def parse_table(content)
          parse(XA::Rules::Parse::TableParser, content)
        end

        private
        
        def maybe_convert_value(v)
          cv = [
            [/^"(\w+)"$/, :to_s],
            [/^([0-9]+)$/, :to_s],
          ].map do |re|
            m = re[0].match(v)
            m ? m[1].send(re[1]) : nil
          end.compact.first

          cv || v
        end

        OPS = {
          '==' => 'eq',
          '>'  => 'gt',
          '<'  => 'lt',
          '>=' => 'gte',
          '<=' => 'lte',
        }

        def build_reference_operand(opr)
          t = opr.keys.first
          case t
          when :section
            rv = { 'section' => opr[t][:section].to_s, 'key' => opr[t][:key].to_s }
          when :context
            rv = { 'section' => '_context', 'key' => opr[t][:key].to_s }
          when :virtual
            rv = { 'section' => '_virtual' }
          when :local
            rv = { 'section' => '_local', 'key' => opr[t][:key].to_s }
          end

          rv.merge('type' => 'reference') if rv
        end

        def build_value_operand(opr)
          t = opr.keys.first
          case t
          when :string
            { 'type' => 'string', 'value' => maybe_convert_value(opr[t].to_s) }
          when :number
            { 'type' => 'number', 'value' => maybe_convert_value(opr[t].to_s) }
          end
        end

        def build_assignment_operand(opr)
          build_reference_operand(opr) || build_value_operand(opr.fetch(:value, {}))
        end
        
        def build_operand(opr)
          t = opr.keys.first
          case t
          when :reference
            build_reference_operand(opr[t])
          when :key
            { 'type' => 'key', 'value' => opr[t].to_s }
          when :name
            { 'type' => 'name', 'value' => opr[t].to_s }
          when :value
            build_value_operand(opr[t])
          else
            { 'type' => 'unk' }
          end
        end
        
        def build_expr(expr)
          {
            'left'  => build_operand(expr[:left]),
            'right' => build_operand(expr[:right]),
            'op'    => OPS.fetch(expr[:op].to_s, 'unk'),
          }
        end

        def build_column(col)
          whens = col[:whens]
          whens = [whens] if whens.class == Hash
          source = col[:source].to_s
          {
            table: build_reference_operand(col[:reference]),
            col: {
              'name'       => col.fetch(:name, source).to_s,
              'source'     => source,
            }.tap do |col|
              col['whens'] = whens.map { |wh| build_expr(wh[:expr]) } if whens
            end,
          }
        end

        def build_column_import(col)
          whens = col[:whens]
          whens = [whens] if whens.class == Hash
          {
            table: build_reference_operand(col[:reference]),
            col: {
              'columns' => col.fetch(:column_names, []).map { |o| o[:name].to_s },
            }.tap do |col|
              col['whens'] = whens.map { |wh| build_expr(wh[:expr]) } if whens
            end
          }
        end
        
        def build_columns(cols)
          cols.map do |col|
            t = col.keys.first
            case t
            when :column
              build_column(col[t])
            when :column_import
              build_column_import(col[t])
            end
          end.inject({}) do |o, col|
            table_name = col[:table]
            table_cols = o.fetch(table_name, [])
            o.merge(table_name => table_cols + [col[:col]])
          end.map do |k, v|
            {
              'table'   => k,
              'sources' => v
            }
          end
        end
        
        def build_assemble(stm)
          cols = stm[:columns]
          cols = [cols] if cols.class == Hash
          {
            'table_name' => stm[:table_name].to_s,
            'columns'    => build_columns(cols),
          }
        end

        def build_filter(stm)
          whens = stm.fetch(:whens, [])
          whens = [whens] if whens.class == Hash
          {
            'table'   => build_reference_operand(stm[:table]),
            'filters' => whens.map do |when_stm|
              build_expr(when_stm[:expr])
            end
          }
        end
        
        def build_keep(stm)
          { 'table_name' => stm[:table_name].to_s }
        end

        def build_function(fn_stm)
          {
            "name" => fn_stm[:name].to_s,
            "args" => fn_stm[:args].map(&method(:build_assignment_expr)),
          }
        end

        def build_assignment_expr(expr)
          at = expr.keys.first
          case at
          when :function
            {
              "type" => "function",
            }.merge(build_function(expr[at]))
          else
            build_assignment_operand(expr)
          end
        end
        
        def build_map(stm)
          assigns = stm[:assignments]
          assigns = [assigns] if assigns.class == Hash
          {
            'table' => build_reference_operand(stm[:table]),
            'assignments' => assigns.inject([]) do |a, assign|
              a + [{ 'source' => build_assignment_expr(assign[:expr]), 'target' => assign[:name].to_s }]
            end
          }
        end

        def build_reduce(stm)
          assigns = stm[:assignments]
          assigns = [assigns] if assigns.class == Hash
          whens = stm.fetch(:whens, [])
          whens = [whens] if whens.class == Hash
          {
            'table' => build_reference_operand(stm[:table]),
            'assignments' => assigns.inject([]) do |a, assign|
              a + [{ "source" => build_assignment_expr(assign[:expr]), 'target' => assign[:name].to_s }]
            end,
            'filters' => whens.map do |when_stm|
              build_expr(when_stm[:expr])
            end,
          }
        end
        
        def build_when(stm)
          {
            'expr' => build_expr(stm[:expr]),
          }
        end

        def build_revise(stm)
          revisions = stm[:revisions]
          revisions = [revisions] if revisions.class == Hash
          {
            'table'   => build_reference_operand(stm[:table]),
            'revisions' => revisions.map do |rev|
              {
                'op'     => rev[:op].to_s.downcase,
                'source' => {
                  'column' => rev[:key].to_s
                }.tap do |o|
                  o['table'] = build_reference_operand(rev[:table]) if rev.key?(:table)
                end,
              }
            end
          }
        end

        def build_require(stm)
          {
            'reference' => [:package, :id, :version].inject({}) do |o, k|
              o.merge(k.to_s => stm[:reference][k].to_s)
            end.tap do |o|
              o['name'] = stm.fetch(:name, o['id']).to_s
            end,
            'indexes' => stm.fetch(:indexes, []).map do |idx|
              idx[:column].to_s
            end,
          }
        end

        def build_effective(stm)
          stm.fetch(:exprs, []).inject({}) do |o, expr|
            k = expr.keys.first
            v = nil
            case k
            when :in
              v = { 'jurisdictions' => expr[k].class == Hash ? [expr[k][:key].to_s] : expr[k].map { |o| o[:key].to_s } }
            when :for
              v = { 'keys' => expr[k].class == Hash ? [expr[k][:key].to_s] : expr[k].map { |o| o[:key].to_s } }
            when :from
              v = { 'starts' => expr[k].to_s }
            when :to
              v = { 'ends' => expr[k].to_s }
            when :timezone
              v = { 'timezone' => expr[k].to_s }
            end
            v ? o.merge(v) : o
          end
        end

        def build_meta(stm)
          exprs = stm.fetch(:exprs, [])
          (exprs.class == Hash ? [exprs] : exprs).inject({}) do |o, expr|
            k = expr.keys.first
            o.merge({ k.to_s => expr[k].to_s.gsub('"', '')})
          end
        end

        def build_data(stm)
          {
            'location' => stm[:location].to_s,
          }.tap do |o|
            o['checksum'] = stm[:checksum].to_s if stm.key?(:checksum)
          end
        end

        def build_refine(stm)
          {
            'table' => build_reference_operand(stm[:table]),
            'refined_name' => stm[:refined_name].to_s,
          }.tap do |o|
            o['refinements'] = stm[:refinements].collect do |r|
              k = r.keys.first
              v = r[k]
              { 'name' => k.to_s }.tap do |ro|
                case k
                when :map
                  ro['assignment'] = {
                    'target' => v[:name].to_s,
                    'source' => build_assignment_expr(v[:expr]),
                  }
                when :filter
                  ro['condition'] = build_expr(v[:expr])
                when :take
                  tk = v.keys.first
                  tv = v[tk]
                  case tk
                  when :expr
                    ro['condition'] = build_expr(tv)
                  when :function
                    ro['function'] = build_function(tv)
                  end
                end
              end
            end if stm.key?(:refinements) && stm[:refinements].any?
          end
        end
        
        def parse(klass, content)
          @step_fns ||= {
            assemble: method(:build_assemble),
            filter: method(:build_filter),
            keep: method(:build_keep),
            map: method(:build_map),
            reduce: method(:build_reduce),
            require: method(:build_require),
            revise: method(:build_revise),
            refine: method(:build_refine),
          }

          content = content.split(/\n/).map { |ln| ln.gsub(/\#.*/, '') }.join('')

          tree = content.empty? ? [] : klass.new.parse_with_debug(content)
          tree = [tree] if tree.class == Hash

          (tree || []).inject({}) do |o, stms|
            t = stms.keys.first
            stm = stms[t]

            case t
            when :when
              expr = build_when(stm)
              whens = o.fetch('whens', {})
              section = expr['expr']['left']['section']
              o.merge('whens' => whens.merge(section => whens.fetch(section, []) + [expr]))
            when :effective
              expr = build_effective(stm)
              effectives = o.fetch('effective', [])
              o.merge('effective' => effectives << expr)
            when :meta
              expr = build_meta(stm)
              meta = o.fetch('meta', {})
              o.merge('meta' => meta.merge(expr))
            when :data
              expr = build_data(stm)
              data = o.fetch('data', [])
              o.merge('data' => data + [expr])
            else
              o.merge('steps' => o.fetch('steps', []) + [@step_fns[t].call(stm).merge('name' => t.to_s)])
            end
          end
        end
      end
    end
  end
end
