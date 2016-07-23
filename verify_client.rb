require 'awesome_print'
require 'xa/registry/client'

(registry, rule_ref, since) = ARGV

cl = XA::Registry::Client.new(registry)
puts '> rule content'
ap cl.rule_by_reference(*rule_ref.split(/:/))

puts '> rules'
ap cl.rules

if since
  puts '> rules since'
  ap cl.rules(since)
end
