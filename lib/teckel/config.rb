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

    # @!visibility protected
    def initialize
      @config = {}
    end

    # @!visibility protected
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
  end
end
