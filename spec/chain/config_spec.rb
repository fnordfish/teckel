# frozen_string_literal: true

RSpec.describe Teckel::Chain do
  let(:result_class) do
    Class.new(Teckel::Operation::Result) do
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
  end

  let(:dummy_step) do
    Class.new do
      include Teckel::Operation

      input none
      output ->(o) { o }
      error none

      def call(_)
        success! settings
      end
    end
  end

  let(:chain) do
    dummy_step = self.dummy_step
    result_class = self.result_class
    Class.new do
      include Teckel::Chain

      # need to define a step to make this a valid chain
      step :one, dummy_step

      result result_class
    end
  end

  describe ".result_constructor" do
    it "default" do
      expect(chain.result_constructor).to eq(result_class.method(:[]))
    end

    it "proc constructor" do
      constructor = ->(value, success, step) {
        result.new(value, success, step, time: Time.now.to_i)
      }

      chain.result_constructor constructor

      expect(chain.result_constructor).to equal(constructor)
    end

    it "method symbol" do
      chain.result_constructor :new

      expect(chain.result_constructor).to eq(result_class.method(:new))
    end

    it "missing method symbol defaults to DEFAULT_CONSTRUCTOR" do
      chain.result_constructor :not_there
      expect(chain.result_constructor).to eq(result_class.method(:[]))
    end

    it "String value defaults to DEFAULT_CONSTRUCTOR" do
      chain.result_constructor "any thing"
      expect(chain.result_constructor).to eq(result_class.method(:[]))
    end
  end
end
