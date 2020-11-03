# frozen_string_literal: true

module TeckelChainDefaultSettingsTest
  class MyOperation
    include Teckel::Operation
    result!

    settings Struct.new(:say, :other)
    settings_constructor ->(data) { settings.new(*data.values_at(*settings.members)) } # ruby 2.4 way for `keyword_init: true`

    input none
    output Hash
    error none

    def call(_)
      success! settings.to_h
    end
  end

  class Chain
    include Teckel::Chain

    default_settings!(a: { say: "Chain Default" })

    step :a, MyOperation
  end
end

RSpec.describe Teckel::Chain do
  specify "call chain without settings, uses default settings" do
    result = TeckelChainDefaultSettingsTest::Chain.call
    expect(result.success).to eq(say: "Chain Default", other: nil)
  end

  specify "call chain with explicit settings, overwrites defaults" do
    result = TeckelChainDefaultSettingsTest::Chain.with(a: { other: "What" }).call
    expect(result.success).to eq(say: nil, other: "What")
  end
end
