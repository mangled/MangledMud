# WIP - try to automatically convert the majority of phrases!!!!
# this may turn out harder than doing it by hand
require "find"
require 'yaml'
require 'pp'

# load the phrases dictionary
phrases = YAML.load_file('./lib/phrases.yml')

# first get all ruby files under here
files = []
Find.find('.') do |file|
  next if File.extname(file) != ".rb"
  files << file
end

# For each file, find uses of:
# Interface.do_notify(player...
# and
# Interface.expects(:do_notify).with('name',
files.each do |filename|
  puts "Parsing #{filename}"
  match_notify = /(\s*Interface\.do_notify\(\w+,)\s*(["']{1}.*?)\)(.*)/
  match_expects = /(\s*Interface\.expects\(:do_notify\)\.with\([\w'"]+,)\s*(["']{1}.*?)\)(.*)/
  open(filename + ".tmp", "w+") do |out|
    IO.foreach(filename) do |line|
      m1 = line.match(match_notify)
      m2 = line.match(match_expects)
      if m1
        found = phrases.find {|k, v| v == m1[2][1..-2] }
        if found
          #raise "poo2" if m1[3].strip.length != 0
          puts "matched #{m1[2]} with \"#{found[1]}\"key: #{found[0]}"
          out.puts(m1[1] + " Phrasebook.lookup('#{found[0]}')" + ")" + m1[3].strip)
        end
      elsif m2
        found = phrases.find {|k, v| v == m2[2][1..-2] }
        if found
          #raise "poo2 #{m2[3]}" if m2[3].strip.length != 0
          puts "matched #{m2[2]} with \"#{found[1]}\" key: #{found[0]}"
          out.puts(m2[1] + " Phrasebook.lookup('#{found[0]}')" + ")" + m2[3].strip)
        end
      else
        out.puts(line.chomp())
      end
    end
  end
end
