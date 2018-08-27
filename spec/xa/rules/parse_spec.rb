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
require 'radish/expects'
require 'xa/rules/parse/content'

describe XA::Rules::Parse do
  include XA::Rules::Parse::Content
  include Radish::Expects

  {
    rule: [
      'assemble',
      'filter',
      'keep',
      'map',
      'reduce',
      'require',
      'revise',
      'when',
      'whitespace',
      'effective',
      'meta',
    ],
    table: [
      'effective',
      'meta',
      'data',
    ],
  }.each do |t, vals|
    vals.each do |n|
      it "should parse syntax (#{t}/#{n})" do
        load_expects(["spec/files/keywords/#{n}.json"], method("parse_#{t}")) do |ex, ac|
          expect(ac).to eql(ex)
        end
      end
    end
  end

  Dir.glob('spec/files/rules/*.rule').each do |ffn|
    (dn, fn) = File.split(ffn)
    it "should parse: #{fn}" do
      ex = MultiJson.decode(File.read(File.join(dn, "#{File.basename(ffn, '.rule')}.json")))
      ac = parse_rule(IO.read(ffn))
      expect(ac['whens']).to eql(ex['whens'])
      ac['steps'].each_with_index do |ac_step, i|
        expect(ac_step).to eql(ex['steps'][i])
      end
    end
  end
end
