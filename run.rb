require 'multi_json'

require_relative './lib/xa/rules/parse'
require_relative './lib/xa/rules/interpret'

tables = {}

def parse_file(fn)
  include XA::Rules::Parse

  File.open(fn) do |f|
    yield(parse_buffer(f.read))
  end
end

def interpret_res(res, tables)
  include XA::Rules::Interpret
  rule = interpret(res)
  yield(rule.execute(tables))
end

puts "> running contents of #{ARGV.first}"

Dir.glob(File.join(ARGV.first, 'table.*.json')).each do |fn|
  puts ">> loading table from #{File.basename(fn)}"
  File.open(fn) do |f|
    tables[File.basename(fn).split('.')[1]] = MultiJson.load(f.read)
  end
end

rule_fn = Dir.glob(File.join(ARGV.first, '*.xalgo')).first
puts ">> using rule #{File.basename(rule_fn)}"

parse_file(rule_fn) do |res|
  interpret_res(res, tables) do |exec_res|
    puts ">> result: #{exec_res.status}"
    if exec_res.status == :ok
      puts '>> result tables'
      exec_res.tables.each do |n, content|
        puts ">>> #{n}"
        content.each do |r|
          puts ">>>> #{r}"
        end
      end
    end
  end
end

