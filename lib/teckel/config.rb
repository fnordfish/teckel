# frozen_string_literal: true

module Teckel
  class Config
    # @!visibility private
    def initialize
      @config = {}
    end

    # Allow getting or setting a value, with some weird rules:
    # - The +value+ might not be +nil+
    # - Setting via +value+ is allowed only once. Successive calls will raise a {FrozenConfigError}
    # - Setting via +block+ works almost like {Hash#fetch}:
    #   - returns the existing value if key is present
    #   - sets (and returns) the blocks return value otherwise
    # - calling without +value+ and +block+ works like {Hash#[]}
    #
    # @raise [FrozenConfigError] When overwriting a key
    # @!visibility private
    def for(key, value = nil, &block)
      if value.nil?
        if block
          @config[key] ||= @config.fetch(key, &block)
        else
          @config[key]
        end
      elsif @config.key?(key)
        raise FrozenConfigError, "Configuration #{key} is already set"
      else
        @config[key] = value
      end
    end

    # @!visibility private
    def replace(key)
      @config[key] = yield if @config.key?(key)
    end

    # @!visibility private
    def freeze
      @config.freeze
      super
    end

    # @!visibility private
    def dup
      super.tap do |copy|
        copy.instance_variable_set(:@config, @config.dup)
      end
    end
  end
end
