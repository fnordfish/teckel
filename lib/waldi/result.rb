# frozen_string_literal: true

module Waldi
  # Wrapper for +output+ and +error+ return values of Operations
  #
  # @example asking for status
  #
  #   Waldi::Result.new("some output", true).successful? #=> true
  #   Waldi::Result.new("some output", true).failure? #=> false
  #
  #   Waldi::Result.new("some error", false).successful? #=> false
  #   Waldi::Result.new("some error", false).failure? #=> true
  #
  # @example Use +.value+ to get the wrapped value regardless of success state
  #
  #   Waldi::Result.new("some output", true).value #=> "some output"
  #   Waldi::Result.new("some error", false).value #=> "some error"
  #
  # @example Use +.success+ to get the wrapped value of a successful result
  #
  #  # Note: The +.failure+ method works just the same for successful results
  #  Waldi::Result.new("some output", true).success #=> "some output"
  #  Waldi::Result.new("some error", false).success #=> nil
  #  Waldi::Result.new("some error", false).success("other default") #=> "other default"
  #  Waldi::Result.new("some error", false).success { |value| "Failed: #{value}" } #=> "Failed: some error"
  #
  # @api public
  class Result
    # @param value [Mixed] the value/payload of the result.
    # @param success [Bool] whether this is a successful result
    def initialize(value, success)
      @value = value
      @success = success
    end

    # @!attribute [r] value
    # @return [Mixed] the value/payload
    attr_reader :value

    def successful?
      @success
    end

    def failure?
      !@success
    end

    def failure(default = nil, &block)
      return @value if !@success
      return yield(@value) if block

      default
    end

    def success(default = nil, &block)
      return @value if @success

      return yield(@value) if block

      default
    end
  end
end
