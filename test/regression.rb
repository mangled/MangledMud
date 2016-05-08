require 'rubygems'
require 'test/unit'
require 'bundler/setup'
require 'diff/lcs'
require 'diff/lcs/array'
require 'mocha/test_unit'
require_relative 'include'
require_relative 'commands'
require_relative 'helpers'

module MangledMud

  class TestRegression < Test::Unit::TestCase

    include TestHelpers

    def cmd_files
      Dir.glob("./test/commands/*.cmd")
    end

    def pass_file(cmd_file)
      pass_file = Dir.glob(cmd_file.gsub(".cmd", ".pass"))
      assert_equal(1, pass_file.length)
      pass_file[0]
    end

    def test_process_command_regressions
      cmd_files().each do |cmd_file|
        db = minimal()
        current_result = open(cmd_file) {|content| CommandHelpers.collect_responses(db, "dump", content) }
        tmp_file = cmd_file.gsub(".cmd", ".tmp")
        open(tmp_file, "wb") {|file| file.write(current_result.join)}
        pass_file = pass_file(cmd_file)
        if pass_file.length == 0
          raise "Missing pass file for #{cmd_file}"
        else
          # Faf, due to windows/linux diff and eol's
          pass = open(pass_file) {|f| f.readlines }
          curr = open(tmp_file) {|f| f.readlines }
          diffs = Diff::LCS.diff(curr, pass)
          if diffs.length > 0
            diffs.each do |diff|
              diff.each do |change|
                puts "#{change.position} #{change.action} #{change.element}"
              end
            end
            assert_equal(0, diffs.length, "regression failed for #{cmd_file}")
          else
            File.delete(tmp_file)
          end
        end
        db.free()
      end
    end
  end
end


