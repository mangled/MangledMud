# WIP - try to automatically convert the majority of phrases!!!!
# this may turn out harder than doing it by hand
require "find"
require 'yaml'
require 'fileutils'
require 'pp'

# load the phrases dictionary
phrases = YAML.load_file('./lib/phrases.yml')

# first get all ruby files under here
files = []
#Find.find('./lib') do |file|
#  next if File.extname(file) != ".rb"
#  files << file
#end
Find.find('./test') do |file|
  next if File.extname(file) != ".rb"
  files << file
end

# For each file, find uses of:
# Interface.do_notify(player...
# and
# Interface.expects(:do_notify).with('name',
files.each do |filename|
  puts "Parsing #{filename}"
  #match_notify = /(\s*Interface\.do_notify\(\w+,)\s*(["']{1}.*?)\)(.*)/
  match_expects = /(\s*Interface\.expects\(:do_notify\)\.with\([\w'"]+,)\s*(["']{1}.*?)\)(.*)/
  tmp_name = filename.gsub(".rb", ".tmp")
  FileUtils.cp(filename, tmp_name)
  puts "#{filename} --> #{tmp_name}"
  open(filename, "w+") do |out|
    IO.foreach(tmp_name) do |line|
      m2 = line.match(match_expects)
      if m2
        text = m2[2][1..-2] # strip off "'s
        replaced = false
        phrases.each do |key, phrase|
          if phrase.include?'%s'
              phrase_match = phrase.gsub(/%[sd]/, "(\\w+)")
          
              m = text.match(phrase_match)
              if m # => line matched the phrase
                  puts "match \"#{text}\" with \"#{phrase}\" key: #{key}"
                  capture_args = m.captures.collect {|a| "\"" + a + "\"" }
                  capture_args = capture_args.join(", ")
                  puts "args: #{capture_args}"
                  s = (m2[1] + " Phrasebook.lookup('#{key}', " + capture_args + ")" + ")" + m2[3].strip)
                  puts(s)
                  out.puts(s)
                  replaced = true
                  break
              end
          end
        end
        unless replaced
          puts "Note: found a match but no key for #{m2[2]}"
          out.puts(line.chomp())
        end
      else
        out.puts(line.chomp())
      end
    end
  end
  File.delete(tmp_name)
end
