# frozen_string_literal: true

module TeckelChainNoneInputTest
  class MyOperation
    include Teckel::Operation
    result!

    settings Struct.new(:say)

    input none
    output String
    error none

    def call(_)
      success!(settings&.say || "Called")
    end
  end

  class Chain
    include Teckel::Chain

    step :a, MyOperation
  end
end

RSpec.describe Teckel::Chain do
  specify "call chain without input value" do
    result = TeckelChainNoneInputTest::Chain.call
    expect(result.success).to eq("Called")
  end

  specify "call chain runner without input value" do
    result = TeckelChainNoneInputTest::Chain.with(a: "What").call
    expect(result.success).to eq("What")
  end
end
