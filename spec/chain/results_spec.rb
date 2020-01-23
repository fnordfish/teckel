# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

RSpec.describe Teckel::Chain do
  module TeckelChainResultTest
    class Message
      include ::Teckel::Operation

      result!

      input Types::Hash.schema(message: Types::String)
      error none
      output Types::String

      def call(input)
        input[:message].upcase
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
          alias :[] :new # Alias the default constructor to :new
        end

        attr_reader :opts, :step
      end

      result_constructor ->(value, success, step) {
        result.new(value, success, step, time: Time.now.to_i)
      }
    end
  end

  specify do
    result = TeckelChainResultTest::Chain.call(message: "Hello World!")
    expect(result).to be_successful
    expect(result.success).to eq("HELLO WORLD!")
    expect(result.opts).to include(time: kind_of(Integer))
  end
end
