require "find"
require 'yaml'
require 'fileutils'
require 'pp'

# load the phrases dictionary
phrases = YAML.load_file('./lib/phrases.yml')

# first get all ruby files under here
lib_files = []
Find.find('./lib') do |file|
  next if File.extname(file) != ".rb"
  lib_files << file
end
test_files = []
Find.find('./test') do |file|
  next if File.extname(file) != ".rb"
  test_files << file
end

def find(filenames)
  keys = {}
  pb_match = /Phrasebook\.lookup\('(.*?)'/
  filenames.each do |filename|
      IO.foreach(filename) do |line|
        m = line.match(pb_match)
        if m
          keys[m[1]] = 0 unless keys.has_key? m[1]
          keys[m[1]] += 1
        end
      end
  end
  keys
end

lib_keys = find(lib_files)
test_keys = find(test_files)

lib_k = lib_keys.keys()
test_keys.keys().each do |test_key|
  puts "in test only #{test_key}" unless lib_k.include?(test_key)
end
