# frozen_string_literal: true

module Teckel
  # Wrapper for +output+ and +error+ return values of Operations
  #
  # @example asking for status
  #
  #   Teckel::Result.new("some output", true).successful? #=> true
  #   Teckel::Result.new("some output", true).failure? #=> false
  #
  #   Teckel::Result.new("some error", false).successful? #=> false
  #   Teckel::Result.new("some error", false).failure? #=> true
  #
  # @example Use +.value+ to get the wrapped value regardless of success state
  #
  #   Teckel::Result.new("some output", true).value #=> "some output"
  #   Teckel::Result.new("some error", false).value #=> "some error"
  #
  # @example Use +.success+ to get the wrapped value of a successful result
  #
  #  # Note: The +.failure+ method works just the same for successful results
  #  Teckel::Result.new("some output", true).success #=> "some output"
  #  Teckel::Result.new("some error", false).success #=> nil
  #  Teckel::Result.new("some error", false).success("other default") #=> "other default"
  #  Teckel::Result.new("some error", false).success { |value| "Failed: #{value}" } #=> "Failed: some error"
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
