# Copyright (C) 2018 Don Kelly <karfai@gmail.com>

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
require 'parslet'
require 'parslet/convenience'

module XA
  module Rules
    module Parse
      class BasicParser < Parslet::Parser
        rule(:semi)               { str(';') }
        rule(:space)              { match('\s').repeat(1) }

        rule(:kw_in)              { match('[iI]') >> match('[nN]') }
        rule(:kw_to)              { match('[tT]') >> match('[oO]') }
        rule(:kw_timezone)        { match('[tT]') >> match('[iI]') >> match('[mM]') >> match('[eE]') >> match('[zZ]') >> match('[oO]') >> match('[nN]') >> match('[eE]') }
        rule(:kw_for)             { match('[fF]') >> match('[oO]') >> match('[rR]') }
        rule(:kw_effective)       { match('[eE]') >> match('[fF]') >> match('[fF]') >> match('[eE]') >> match('[cC]') >> match('[tT]') >> match('[iI]') >> match('[vV]') >> match('[eE]') }
        rule(:kw_meta)            { match('[mM]') >> match('[eE]') >> match('[tT]') >> match('[aA]') }
        rule(:kw_criticality)     { match('[cC]') >> match('[rR]') >> match('[iI]') >> match('[tT]') >> match('[iI]') >> match('[cC]') >> match('[aA]') >> match('[lL]') >> match('[iI]') >> match('[tT]') >> match('[yY]') }
        rule(:kw_version)         { match('[vV]') >> match('[eE]') >> match('[rR]') >> match('[sS]') >> match('[iI]') >> match('[oO]') >> match('[nN]') }
        rule(:kw_runtime)         { match('[rR]') >> match('[uU]') >> match('[nN]') >> match('[tT]') >> match('[iI]') >> match('[mM]') >> match('[eE]') }
        rule(:kw_manager)         { match('[mM]') >> match('[aA]') >> match('[nN]') >> match('[aA]') >> match('[gG]') >> match('[eE]') >> match('[rR]') }
        rule(:kw_maintainer)      { match('[mM]') >> match('[aA]') >> match('[iI]') >> match('[nN]') >> match('[tT]') >> match('[aA]') >> match('[iI]') >> match('[nN]') >> match('[eE]') >> match('[rR]') }

        rule(:effective_key)       { (match('\w') | str('-') | str(':') | str('/') | str('.')).repeat }
        rule(:effective_key_list)  { effective_key.as(:key) >> (comma >> space.maybe >> effective_key.as(:key)).repeat }
        
        rule(:effective_in)        { kw_in >> space >> effective_key_list.as(:in) }
        rule(:effective_from)      { kw_from >> space >> effective_key.as(:from) }
        rule(:effective_to)        { kw_to >> space >> effective_key.as(:to) }
        rule(:effective_timezone)  { kw_timezone >> space >> effective_key.as(:timezone) }
        rule(:effective_for)       { kw_for >> space >> effective_key_list.as(:for) }
        rule(:effective_expr)      { effective_in | effective_from | effective_to | effective_timezone | effective_for }
        rule(:effective_expr_list) { effective_expr >> (space >> effective_expr).repeat }
        rule(:effective_statement) { kw_effective >> space >> effective_expr_list.as(:exprs) }

        rule(:meta_key)            { (match('\w') | str('-') | str(':') | str('/') | str('.') | str('@') | str('<') | str('>') | str('.')).repeat }
        
        rule(:meta_criticality)    { kw_criticality >> space >> str('"') >> meta_key.as(:criticality) >> str('"') }
        rule(:meta_version)        { kw_version >> space >> str('"') >> meta_key.as(:version) >> str('"') }
        rule(:meta_runtime)        { kw_runtime >> space >> str('"') >> meta_key.as(:runtime) >> str('"') }
        rule(:meta_manager)        { kw_manager >> space >> str('"') >> (meta_key >> (space >> meta_key).repeat).as(:manager) >> str('"') }
        rule(:meta_maintainer)     { kw_maintainer >> space >> str('"') >> (meta_key >> (space >> meta_key).repeat).as(:maintainer) >> str('"') }
        rule(:meta_expr)           { meta_criticality | meta_version | meta_runtime | meta_manager | meta_maintainer }
        rule(:meta_expr_list)      { meta_expr >> (space >> meta_expr).repeat }
        rule(:meta_statement)      { kw_meta >> space >> meta_expr_list.as(:exprs) }

        rule(:basic_statement)     { effective_statement.as(:effective) | meta_statement.as(:meta) }

        rule(:statement)           { (basic_statement | extension_statement) >> semi }
        rule(:statements)          { statement >> (space.maybe >> statement).repeat >> space.maybe }

        root(:statements)
      end
    end
  end
end
