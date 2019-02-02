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
require_relative './basic_parser'

require 'parslet'
require 'parslet/convenience'

module XA
  module Rules
    module Parse
      class RuleParser < BasicParser
        rule(:kw_when)            { match('[wW]') >> match('[hH]') >> match('[eE]') >> match('[nN]') }
        rule(:kw_assemble)        { match('[aA]') >> match('[sS]') >> match('[sS]') >> match('[eE]') >> match('[mM]') >> match('[bB]') >> match('[lL]') >> match('[eE]') }
        rule(:kw_column)          { match('[cC]') >> match('[oO]') >> match('[lL]') >> match('[uU]') >> match('[mM]') >> match('[nN]') }
        rule(:kw_columns)         { match('[cC]') >> match('[oO]') >> match('[lL]') >> match('[uU]') >> match('[mM]') >> match('[nN]') >> match('[sS]') }
        rule(:kw_map)             { match('[mM]') >> match('[aA]') >> match('[pP]') }
        rule(:kw_using)           { match('[uU]') >> match('[sS]') >> match('[iI]') >> match('[nN]') >> match('[gG]') }
        rule(:kw_require)         { match('[rR]') >> match('[eE]') >> match('[qQ]') >> match('[uU]') >> match('[iI]') >> match('[rR]') >> match('[eE]') }
        rule(:kw_revise)          { match('[rR]') >> match('[eE]') >> match('[vV]') >> match('[iI]') >> match('[sS]') >> match('[eE]') }
        rule(:kw_index)           { match('[iI]') >> match('[nN]') >> match('[dD]') >> match('[eE]') >> match('[xX]') }
        rule(:kw_as)              { match('[aA]') >> match('[sS]') }
        rule(:kw_keep)            { match('[kK]') >> match('[eE]') >> match('[eE]') >> match('[pP]') }
        rule(:kw_filter)          { match('[fF]') >> match('[iI]') >> match('[lL]') >> match('[tT]') >> match('[eE]') >> match('[rR]') }
        rule(:kw_reduce)          { match('[rR]') >> match('[eE]') >> match('[dD]') >> match('[uU]') >> match('[cC]') >> match('[eE]') }
        rule(:kw_add)             { match('[aA]') >> match('[dD]') >> match('[dD]') }
        rule(:kw_update)          { match('[uU]') >> match('[pP]') >> match('[dD]') >> match('[aA]') >> match('[tT]') >> match('[eE]') }
        rule(:kw_delete)          { match('[dD]') >> match('[eE]') >> match('[lL]') >> match('[eE]') >> match('[tT]') >> match('[eE]') }
        rule(:kw_refine)          { match('[rR]') >> match('[eE]') >> match('[fF]') >> match('[iI]') >> match('[nN]') >> match('[eE]') }
        
        rule(:op_gte)             { str('>=') }
        rule(:op_lte)             { str('<=') }
        rule(:op_eq)              { str('==') }
        rule(:op_gt)              { str('>') }
        rule(:op_lt)              { str('<') }

        rule(:string)             { quote >> match('\w').repeat(1) >> quote }
        rule(:number)             { match('[0-9]').repeat(1) }
        rule(:name)               { match('[a-zA-Z]') >> match('\w').repeat }
        rule(:name_list)          { name.as(:name) >> (comma >> space.maybe >> name.as(:name)).repeat }
        rule(:key_name)           { name >> (str('.') >> name).repeat }
        rule(:version)            { number >> dot >> number >> dot >> number }
        rule(:value)              { string.as(:string) | number.as(:number) }

        rule(:section_reference)  { name.as(:section) >> colon >> key_name.as(:key) }
        rule(:context_reference)  { at >> key_name.as(:key) }
        rule(:local_reference)    { key_name.as(:key) }
        rule(:vtable_reference)   { dollar }
        rule(:table_reference)    { section_reference.as(:section) | context_reference.as(:context) | vtable_reference.as(:virtual) }
        rule(:function_reference) { name.as(:name) >> (lparen >> assign_expr >> (space.maybe >> comma >> space.maybe >> assign_expr).repeat >> rparen).as(:args) }
        rule(:reference)          { section_reference.as(:section) | context_reference.as(:context) | local_reference.as(:local) } 
        rule(:operand)            { value.as(:value) | reference.as(:reference) }
        rule(:op)                 { op_lte | op_gte | op_eq | op_lt | op_gt }
        rule(:expr)               { operand.as(:left) >> space.maybe >> op.as(:op) >> space.maybe >> operand.as(:right) }
        
        rule(:when_statement)     { kw_when >> space >> expr.as(:expr) }
        rule(:when_statements)    { when_statement >> (space >> when_statement).repeat }

        rule(:reduce_statement)   { kw_reduce >> space >> table_reference.as(:table) >> space >> assignments.as(:assignments) >> space >> when_statements.as(:whens) }
        
        rule(:require_indexes)    { kw_index >> space >> lsquare >> name.as(:column) >> (comma >> space.maybe >> name.as(:column)).repeat >> rsquare }
        rule(:require_reference)  { key_name.as(:package) >> colon >> name.as(:id) >> colon >> version.as(:version) }
        rule(:require_statement)  { kw_require >> space >> require_reference.as(:reference) >> (space >> require_indexes.as(:indexes)).maybe >> (space >> kw_as >> space >> name.as(:name)).maybe }

        rule(:assemble_column)    { kw_column >> space >> name.as(:source) >> (space >> kw_as >> space >> name.as(:name)).maybe >> space >> kw_from >> space >> reference.as(:reference) >> (space >> when_statements.as(:whens)).maybe }
        rule(:assemble_column_import) { kw_columns >> space >> (lparen >> name_list.as(:column_names) >> rparen >> space).maybe >> kw_from >> space >> reference.as(:reference) >> (space >> when_statements.as(:whens)).maybe }
        rule(:assemble_columnset) { assemble_column.as(:column) | assemble_column_import.as(:column_import) } 
        rule(:assemble_columns)   { assemble_columnset >> (space >> assemble_columnset).repeat }
        rule(:assemble_statement) { kw_assemble >> space >> name.as(:table_name) >> space >> assemble_columns.as(:columns) }

        rule(:keep_statement)     { kw_keep >> space >> name.as(:table_name) }
        
        rule(:assign_expr)        { function_reference.as(:function) | reference | value.as(:value) }
        rule(:assignment)         { kw_using >> space >> key_name.as(:name) >> space.maybe >> eq >> space.maybe >> assign_expr.as(:expr) }
        rule(:assignments)        { assignment >> (space >> assignment).repeat }
        rule(:assign_statement)   { table_reference.as(:table) >> space >> assignments.as(:assignments) }
        rule(:map_statement)      { kw_map >> space >> assign_statement }

        rule(:revision_op)        { kw_add | kw_update | kw_delete }
        rule(:revision_statement) { revision_op.as(:op) >> space >> key_name.as(:key) >> (space >> kw_from >> space >> table_reference.as(:table)).maybe }
        rule(:revision_statements) { revision_statement >> (space >> revision_statement).repeat }
        rule(:revise_statement)   { kw_revise >> space >> table_reference.as(:table) >> space >> revision_statements.as(:revisions) }

        rule(:filter_statement)   { kw_filter >> space >> table_reference.as(:table) >> space >> when_statements.as(:whens) }

        rule(:map_refinement)     { kw_map >> space >> key_name.as(:name) >> space.maybe >> eq >> space.maybe >> assign_expr.as(:expr) }
        rule(:refinements)        { map_refinement.as(:map) }
        rule(:refine_statement)   { kw_refine >> space >> table_reference.as(:table) >> space >> kw_as >> space >> name.as(:refined_name) >> (space >> refinements.repeat(0).as(:refinements)).maybe }

        rule(:extension_statement) { when_statement.as(:when) | require_statement.as(:require) | assemble_statement.as(:assemble) | keep_statement.as(:keep) | map_statement.as(:map) | revise_statement.as(:revise) | filter_statement.as(:filter) | reduce_statement.as(:reduce) | refine_statement.as(:refine) }
      end
    end
  end
end
