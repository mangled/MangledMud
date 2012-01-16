require 'rubygems'
require 'test/unit'
require 'mocha'
require_relative 'defines'
require_relative 'include'
require 'pp'

# Only testing these as they may be non typical comparison routines
module TinyMud
    class TestStringUtil < Test::Unit::TestCase
		def test_string_compare # Zero implies equal - Basically a case insensitive equals
			su = TinyMud::StringUtil.new
			assert_equal(0, su.string_compare(nil, nil))
			assert_not_equal(0, su.string_compare("a", nil))
			assert_not_equal(0, su.string_compare(nil, "a"))
			assert_equal(0, su.string_compare("a", "a"))
			assert_equal(0, su.string_compare("A", "a"))
			assert_equal(0, su.string_compare("a", "A"))
			assert_equal(0, su.string_compare("abcdef", "abcDeF"))
			assert_not_equal(0, su.string_compare("abcdex", "abcDeF"))
		end

		def test_string_prefix # Check (case insensitive) that the string has the prefix
			# Returns true (1) or false (0)
			su = TinyMud::StringUtil.new
			assert_equal(1, su.string_prefix(nil, nil))
			assert_equal(0, su.string_prefix("foo", "bar"))
			assert_equal(0, su.string_prefix("", "bar"))
			assert_equal(1, su.string_prefix("barfoo", "bar"))
			assert_equal(1, su.string_prefix("bArfoo", "bar"))
			assert_equal(1, su.string_prefix("bAR foo", "bar"))
			assert_equal(0, su.string_prefix(" bAR foo", "bar"))
		end
		
		def test_string_match # Is a substring of s, match on start of word, if so return address else zero
			su = TinyMud::StringUtil.new
			assert_equal(0, su.string_match(nil, nil))
			assert_equal(0, su.string_match("hello world", "foo"))
			assert_equal(0, su.string_match("hello world", "ell"))
			assert_not_equal(0, su.string_match("hello world", "hel"))
			assert_not_equal(0, su.string_match("hello world", "wor"))
			assert_not_equal(0, su.string_match("hello world", "WORLD"))
			assert_not_equal(0, su.string_match("hello big world", "WORLD"))
			assert_equal(0, su.string_match("hello big world", "ORLD"))
		end
    end
end
