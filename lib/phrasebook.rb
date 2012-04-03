require 'yaml'

module MangledMud
  
  # Handles localization of the MUD's textual output, it maps a "key" and optional arguments to a "string"
  # defined in the file phrases.yml
  #
  # @note We do not support switching localizations at present, although it would be easy to implement this feature
  # @version 1.0
  class Phrasebook

    @phrases = nil

    # Lookup a phrase based on key, [args] are used to substitute into phrases that require variable values.
    #
    # @param [String] key the key to lookup, see phrases.yml
    # @param [Array Arguments] args an optional array of arguments, required for strings which have variable substitutions, see phrases.yml
    # @return [String] A localized string
    def self.lookup(key, *args)
      @phrases = YAML.load_file(File.join(File.dirname(__FILE__), 'phrases.yml')) if @phrases.nil?
      raise "Missing phrase #{key}" unless @phrases.has_key? key
      @phrases[key] % args
    end
  end
end

