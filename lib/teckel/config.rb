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
    # @param key [Symbol,String] Name of the configuration
    # @param value [Object] Value of the configuration
    # @yield [key] If using in fetch mode and no value has been set
    # @yieldparam key [Symbol,String] Name of the configuration
    # @return [Object]
    # @raise [FrozenConfigError] When overwriting a key
    # @!visibility private
    def for(key, value = nil, &block)
      if value.nil?
        get_or_set(key, &block)
      elsif @config.key?(key)
        raise FrozenConfigError, "Configuration #{key} is already set"
      else
        @config[key] = value
      end
    end

    # @!visibility private
    # @param key [Symbol,String] Name of the configuration
    # @yieldreturn [Object] The new setting
    # @return [Object,nil] The new setting or +nil+ if not replaced
    def replace(key)
      @config[key] = yield if @config.key?(key)
    end

    # @!visibility private
    def freeze
      @config.freeze
      super() # standard:disable Style/SuperArguments
    end

    # @!visibility private
    def dup
      copy = super() # standard:disable Style/SuperArguments
      copy.instance_variable_set(:@config, @config.dup)
      copy
    end

    private def get_or_set(key, &block)
      if block
        @config[key] ||= @config.fetch(key, &block)
      else
        @config[key]
      end
    end
  end
end
