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

require 'multi_json'
require_relative 'lib/xa/rules/parse/content'

include XA::Rules::Parse::Content

# Determines if file is a rule or table, and runs relevant library method.
def parse_file(input_file, output_file)

    puts "Parsing #{input_file}"

    if output_file == nil
        output_file = "#{input_file}.json"
    end
    if input_file.end_with?(".rule")
        IO.write(output_file, MultiJson.dump(parse_rule(IO.read(input_file)), pretty: true))
    elsif input_file.end_with?(".table")
        IO.write(output_file, MultiJson.dump(parse_table(IO.read(input_file)), pretty: true))
    else
        raise 'File type not *.rule or *.table'
    end
end

# Executes on program start. For each file in a folder, or a single file, runs parse_file
def cli_run
    if ARGV[0] == nil
        raise 'Please provide a .rule or .table file to parse'
    elsif File.directory?(ARGV[0])
        Dir.foreach(ARGV[0]) do |name|
            file = File.join(ARGV[0], name)
            if file.end_with?(".table") || file.end_with?(".rule")
                parse_file(file, nil)
            end
        end
    else
        parse_file(ARGV[0], ARGV[1])
    end
end

# Execute immediately
cli_run
