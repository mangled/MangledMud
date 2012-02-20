# Experiment with putting TinyMUD strings into one place!!!
# WIP
require 'yaml'

module TinyMud
  class Phrasebook

    # Holds the phrases :-)
    @phrases = nil

    # Lookup a phrase based on key, [args] are used to substitute into phrases that
    # require variable values.
    def self.lookup(key, *args)
      @phrases = YAML.load_file('./lib/phrases.yml') if @phrases.nil?
      raise "Missing phrase #{key}" unless @phrases.has_key? key
      @phrases[key] % args
    end
  end
end

puts TinyMud::Phrasebook.lookup('penniless', "fred")
