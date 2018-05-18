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
content = {"meta"=>{"expects"=>{"invoices"=>["buyer_location", "seller_location", "unspsc", "price"]}, "repositories"=>{"xalgo"=>"http://localhost:4000"}}, "actions"=>[{"name"=>"pull", "namespace"=>"xalgo", "table"=>"waemu_members", "version"=>"20160711222232", "as"=>"waemu_members"}, {"name"=>"pull", "namespace"=>"xalgo", "table"=>"eu_members", "version"=>"20160711222232", "as"=>"eu_members"}, {"name"=>"pull", "namespace"=>"xalgo", "table"=>"unspsc_to_hs", "version"=>"20160711222232", "as"=>"unspsc_to_hs"}, {"name"=>"pull", "namespace"=>"eu_taxation", "table"=>"eu_vat_internal", "version"=>"20160711222232", "as"=>"eu_vat_internal"}, {"name"=>"pull", "namespace"=>"eu_taxation", "table"=>"eu_vat_external", "version"=>"20160711222232", "as"=>"eu_vat_external"}, {"name"=>"pull", "namespace"=>"eu_taxation", "table"=>"eu_escalation", "version"=>"20160711222232", "as"=>"eu_escalation"}, {"name"=>"pull", "namespace"=>"waemu_taxation", "table"=>"waemu_cet", "version"=>"20160711222232", "as"=>"waemu_cet"}, {"name"=>"pull", "namespace"=>"mali_taxation","table"=>"mali_st", "version"=>"20160711222232", "as"=>"mali_st"}, {"name"=>"pull", "namespace"=>"mali_taxation", "table"=>"mali_csl", "version"=>"20160711222232", "as"=>"mali_csl"}, {"name"=>"push", "table"=>"invoices"}, {"name"=>"push", "table"=>"unspsc_to_hs"}, {"name"=>"join", "using"=>{"left"=>["unspsc"], "right"=>["unspsc_code"]}, "include"=>{"hs_code"=>"hs_code"}}, {"name"=>"push", "table"=>"waemu_members"}, {"name"=>"inclusion", "using"=>{"left"=>["buyer_location"], "right"=>["code"]}, "include"=>{"is_member"=>"buyer_in_waemu"}}, {"name"=>"push", "table"=>"waemu_members"}, {"name"=>"inclusion", "using"=>{"left"=>["seller_location"], "right"=>["code"]}, "include"=>{"is_member"=>"seller_in_waemu"}}, {"name"=>"push", "table"=>"eu_members"}, {"name"=>"inclusion", "using"=>{"left"=>["buyer_location"], "right"=>["code"]}, "include"=>{"is_member"=>"buyer_in_eu"}}, {"name"=>"push", "table"=>"waemu_cet"}, {"name"=>"join", "using"=>{"left"=>["buyer_in_waemu", "seller_in_waemu", "hs_code"], "right"=>["buyer_member", "seller_member", "hs_code"]}, "include"=>{"multiplier"=>"waemu_multiplier"}}, {"name"=>"push", "table"=>"eu_vat_internal"}, {"name"=>"join", "using"=>{"left"=>["buyer_in_eu", "hs_code"], "right"=>["buyer_member", "hs_code"]}, "include"=>{"multiplier"=>"eu_member_vat_multiplier"}}, {"name"=>"push", "table"=>"eu_vat_external"}, {"name"=>"join", "using"=>{"left"=>["buyer_location", "hs_code"], "right"=>["buyer_country", "hs_code"]}, "include"=>{"multiplier"=>"eu_nonmember_vat_multiplier"}}, {"name"=>"push", "table"=>"eu_escalation"}, {"name"=>"join", "using"=>{"left"=>["buyer_in_eu", "hs_code"], "right"=>["buyer_member", "hs_code"]}, "include"=>{"multiplier"=>"eu_member_esc_multiplier"}}, {"name"=>"push", "table"=>"mali_csl"}, {"name"=>"join", "using"=>{"left"=>["buyer_location", "hs_code"], "right"=>["buyer_country", "hs_code"]}, "include"=>{"multiplier"=>"mali_csl_multiplier"}}, {"name"=>"push", "table"=>"mali_st"}, {"name"=>"join", "using"=>{"left"=>["buyer_location", "hs_code"], "right"=>["buyer_country", "hs_code"]}, "include"=>{"multiplier"=>"mali_st_multiplier"}}, {"name"=>"accumulate", "column"=>"price", "function"=>{"name"=>"mult", "args"=>["waemu_multiplier", "eu_member_vat_multiplier", "eu_nonmember_vat_multiplier", "eu_member_esc_multiplier", "mali_csl_multiplier", "mali_st_multiplier"]}, "result"=>"taxed_price"}, {"name"=>"commit", "table"=>"taxed_invoices", "columns"=>["unspsc", "hs_code", "price", "taxed_price"]}]}

tables = {
  'invoices' => [
    { "buyer_location"=> "MLI", "seller_location"=> "FRA", "unspsc"=> "60131303", "price"=> "839.99" },
    { "buyer_location"=> "MLI", "seller_location"=> "SEN", "unspsc"=> "49121508", "price"=> "5.99" },
    { "buyer_location"=> "MLI", "seller_location"=> "CHN", "unspsc"=> "46161604", "price"=> "35.85" },
    { "buyer_location"=> "NLD", "seller_location"=> "COL", "unspsc"=> "10152054", "price"=> "1.05" }
  ]
}

require 'xa/rules/context'
require 'xa/rules/interpret'

include XA::Rules::Interpret

ctx = XA::Rules::Context.new(tables)
res = ctx.execute(interpret(content))
p res
