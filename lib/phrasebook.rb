# Experiment with putting MangledMUD strings into one place!!!
# WIP
require 'yaml'

module MangledMud
  class Phrasebook

    # Holds the phrases :-)
    @phrases = nil

    # At some point the game could set the locale (at start-up and pull in the correct phrases)
    # E.g. self.locale() -> pulls in right yaml file
    # we are not going to do this as it drove us mad converting all the strings in the first place :-)

    # Lookup a phrase based on key, [args] are used to substitute into phrases that
    # require variable values.
    def self.lookup(key, *args)
      @phrases = YAML.load_file('./lib/phrases.yml') if @phrases.nil?
      raise "Missing phrase #{key}" unless @phrases.has_key? key
      @phrases[key] % args
    end
  end
end

