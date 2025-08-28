# frozen_string_literal: true

require "support/dry_base"
require "support/fake_models"

RSpec.describe Teckel::Config do
  let(:sample_config) do
    Teckel::Config.new
  end

  it "set and retrieve key" do
    sample_config.get_or_set(:some_key, "some_value")
    expect(sample_config.get_or_set(:some_key)).to eq("some_value")
  end

  it "allow default value via block" do
    expect(sample_config.get_or_set(:some_key) { "default" }).to eq("default")
    # and sets the block value
    expect(sample_config.get_or_set(:some_key)).to eq("default")
  end

  it "raises FrozenConfigError when setting a key twice" do
    sample_config.get_or_set(:some_key, "some_value")
    expect { sample_config.get_or_set(:some_key, "other_value") }.to raise_error(Teckel::FrozenConfigError)
  end
end
