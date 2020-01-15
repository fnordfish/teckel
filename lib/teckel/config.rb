# frozen_string_literal: true

module Teckel
  class Config
    @default_constructor = :[]
    class << self
      # @!attribute [r] default_constructor()
      # The default constructor method for +input+, +output+ and +error+ class (default: +:[]+)
      # @return [Class] The Output class

      # @!method default_constructor(sym_or_proc)
      # Set the default constructor method for +input+, +output+ and +error+ class
      #
      # defaults to +:[]+
      #
      # @param sym_or_proc [Symbol,#call] The method name on the +input+,
      #   +output+ and +error+ class or a callable which accepts the
      #   +input+, +output+ or +error+
      #
      # @return [Symbol,#call]
      def default_constructor(sym_or_proc = nil)
        return @default_constructor if sym_or_proc.nil?

        @default_constructor = sym_or_proc
      end
    end

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
