# frozen_string_literal: true

require "support/dry_base"
require "support/fake_models"

module TeckelChainResultTest
  class Message
    include ::Teckel::Operation

    result!

    input Types::Hash.schema(message: Types::String)
    error none
    output Types::String

    def call(input)
      success! input[:message].upcase
    end
  end

  class Chain
    include Teckel::Chain

    step :message, Message

    class Result < Teckel::Operation::Result
      def initialize(value, success, step, opts = {})
        super(value, success)
        @step = step
        @opts = opts
      end

      class << self
        alias_method :[], :new # Alias the default constructor to :new
      end

      attr_reader :opts, :step
    end

    result_constructor ->(value, success, step) {
      result.new(value, success, step, time: Time.now.to_i)
    }
  end
end

RSpec.describe Teckel::Chain do
  specify do
    result = TeckelChainResultTest::Chain.call(message: "Hello World!")
    expect(result).to be_successful
    expect(result.success).to eq("HELLO WORLD!")
    expect(result.opts).to include(time: kind_of(Integer))
  end
end
