require 'rubygems'
require 'bundler/setup'
require 'yard'
require 'yard/rake/yardoc_task'

task :default => ['test:all']

namespace :doc do
  root = File.dirname(__FILE__)
  dest = File.join(root, '.', 'doc')

  desc 'Generate documentation'
  YARD::Rake::YardocTask.new(:yard) do |yt|
    # Default to just the lib directory, uncomment this if we want tests too
    # yt.files   = Dir.glob(File.join(root, '**', '*.rb'))
    yt.options = ['--output-dir', dest, '--readme', File.join(root, 'readme.md'), '--files', File.join(root, 'guide.md')]
  end
end

namespace :test do
  desc "Run a specific regression file on the converted tinymud code (rake :test_script_converted name=foo])"
  task :test_script => [] do |t|
    ENV['TEST_TYPE']='CONVERTED'
    system "ruby ./test/run_command.rb #{ENV['name']}"
  end

  desc "Run all tests on the current conversion code"
  task :all => [] do |t|
    ENV['TEST_TYPE']='CONVERTED'
    system "ruby ./test/test.rb"
  end
end
