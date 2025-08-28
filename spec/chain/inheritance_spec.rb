# frozen_string_literal: true

require "support/dry_base"
require "support/fake_models"

module TeckelChainDefaultsViaBaseClass
  LOG = [] # rubocop:disable Style/MutableConstant

  class LoggingChain
    include Teckel::Chain

    around do |chain, input|
      require "benchmark"
      result = nil
      LOG << Benchmark.measure { result = chain.call(input) }
      result
    end

    freeze
  end

  class OperationA
    include Teckel::Operation

    result!

    input none
    output Types::Integer
    error none

    def call(_)
      success! rand(1000)
    end

    finalize!
  end

  class OperationB
    include Teckel::Operation

    result!

    input none
    output Types::String
    error none

    def call(_)
      success! ("a".."z").to_a.sample
    end

    finalize!
  end

  class ChainA < LoggingChain
    step :roll, OperationA

    finalize!
  end

  class ChainB < LoggingChain
    step :say, OperationB

    finalize!
  end

  class ChainC < ChainB
    finalize!
  end
end

RSpec.describe Teckel::Chain do
  before do
    TeckelChainDefaultsViaBaseClass::LOG.clear
  end

  let(:base_chain) { TeckelChainDefaultsViaBaseClass::LoggingChain }
  let(:chain_a) { TeckelChainDefaultsViaBaseClass::ChainA }
  let(:chain_b) { TeckelChainDefaultsViaBaseClass::ChainB }
  let(:chain_c) { TeckelChainDefaultsViaBaseClass::ChainC }

  it "inherits config" do
    expect(chain_a.around)
    expect(chain_b.around)

    expect(base_chain.steps).to eq([])
    expect(chain_a.steps.size).to eq(1)
    expect(chain_b.steps.size).to eq(1)
  end

  it "runs chain a" do
    expect {
      result = chain_a.call
      expect(result.success).to be_a(Integer)
    }.to change {
      TeckelChainDefaultsViaBaseClass::LOG.size
    }.from(0).to(1)
  end

  it "runs chain b" do
    expect {
      result = chain_b.call
      expect(result.success).to be_a(String)
    }.to change {
      TeckelChainDefaultsViaBaseClass::LOG.size
    }.from(0).to(1)
  end

  it "inherits steps" do
    expect {
      result = chain_c.call
      expect(result.success).to be_a(String)
    }.to change {
      TeckelChainDefaultsViaBaseClass::LOG.size
    }.from(0).to(1)
  end
end
