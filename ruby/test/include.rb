# Switch the extension library that is used in the test.

if ENV['TEST_TYPE'] == 'ORIGINAL' # The original
  puts "Fyi - You are running against the ORIGINAL (c-extensions)"
  require_relative '../lib/original/tinymud'
elsif ENV['TEST_TYPE'] == 'CONVERTED' # The diminishing library
  puts "Fyi - You are running against the CONVERTED (being converted library)"
  require_relative '../lib/converted/tinymud'
  # To-do - require converted ruby class (new folder?) (and disable in tinymud.c)
else
  throw "Unknown test type!"
end

