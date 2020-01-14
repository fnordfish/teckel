# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

RSpec.describe Teckel::Config do
  let(:sample_config) do
    Teckel::Config.new
  end

  it "set and retrieve key" do
    sample_config.for(:some_key, "some_value")
    expect(sample_config.for(:some_key)).to eq("some_value")
  end

  it "allow default value via block" do
    expect(sample_config.for(:some_key) { "default" }).to eq("default")
    # and sets the block value
    expect(sample_config.for(:some_key)).to eq("default")
  end

  it "raises FrozenConfigError when setting a key twice" do
    sample_config.for(:some_key, "some_value")
    expect { sample_config.for(:some_key, "other_value") }.to raise_error(Teckel::FrozenConfigError)
  end

  context "overwriting the default constructor" do
    before do
      @default_value = Teckel::Config.default_constructor
      Teckel::Config.default_constructor(:narf)
    end

    after do
      Teckel::Config.default_constructor(@default_value)
    end

    module TeckelConfigDefaultConstructorTest
      class Pinky
        def self.narf
          "zort"
        end
      end

      class MyOperation
        include Teckel::Operation

        input Pinky
      end
    end

    specify do
      expect(TeckelConfigDefaultConstructorTest::MyOperation.input_constructor).to eq(
        TeckelConfigDefaultConstructorTest::Pinky.method(:narf)
      )
    end
  end
end
