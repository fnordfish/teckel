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
  # @!visibility public
  class Result
    # @param value [Mixed] the value/payload of the result.
    # @param success [Bool] whether this is a successful result
    def initialize(value, success)
      @value = value
      @success = (!!success).freeze
    end

    # @!attribute [r] value
    # @return [Mixed] the value/payload
    attr_reader :value

    # Whether this is a success result
    # @return [Boolean]
    def successful?
      @success
    end

    # Whether this is a error/failure result
    # @return [Boolean]
    def failure?
      !@success
    end

    # Get the error/failure value
    # @yield [Mixed] If a block is given and this is not a failure result, the value is yielded to the block
    # @param  default [Mixed] return this default value if it's not a failure result
    # @return [Mixed] the value/payload
    def failure(default = nil, &block)
      return @value unless @success
      return yield(@value) if block

      default
    end

    # Get the success value
    # @yield [Mixed] If a block is given and this is not a success result, the value is yielded to the block
    # @param  default [Mixed] return this default value if it's not a success result
    # @return [Mixed] the value/payload
    def success(default = nil, &block)
      return @value if @success

      return yield(@value) if block

      default
    end

    def deconstruct
      [@success, @value]
    end

    DECONSTRUCT_KEYS = %i[success value].freeze

    def deconstruct_keys(keys)
      add_success = keys.delete(:success)
      (DECONSTRUCT_KEYS & keys).to_h { |k| [k, public_send(k)] }.tap do |e|
        e[:success] = successful? if add_success
      end
    end
  end
end
