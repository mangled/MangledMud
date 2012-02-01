# Switch the extension library that is used in the test.

if ENV['TEST_TYPE'] == 'ORIGINAL' # The original
  puts "Fyi - You are running against the ORIGINAL (c-extensions)"
  require_relative '../lib/original/tinymud'
elsif ENV['TEST_TYPE'] == 'CONVERTED' # The diminishing library
  # To-do - require converted ruby class (new folder?) (and disable in tinymud.c)
  puts "Fyi - You are running against the CONVERTED (being converted library)"
  require_relative '../lib/converted/tinymud'
  require_relative '../lib/db.rb'
  require_relative '../lib/player.rb'
  #require_relative '../lib/match.rb'
  require_relative '../lib/utils.rb'
  require_relative '../lib/predicates.rb'
  require_relative '../lib/speech.rb'
else
  throw "Unknown test type!"
end
