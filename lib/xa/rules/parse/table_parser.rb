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
require_relative './basic_parser'

require 'parslet'
require 'parslet/convenience'

module XA
  module Rules
    module Parse
      class TableParser < BasicParser
        rule(:kw_data)             { match('[dD]') >> match('[aA]') >> match('[tT]') >> match('[aA]') }
        
        rule(:data_statement)      { kw_data >> space >> key_value.as(:location) >> (space >> key_value.as(:checksum)).maybe }
        
        rule(:extension_statement) { data_statement.as(:data) }
      end
    end
  end
end
