# frozen_string_literal: true

module TeckelOperationDefaultSettings
  class BaseOperation
    include ::Teckel::Operation

    input none
    output Symbol
    error none

    def call(_input)
      success! settings.injected
    end
  end
end

RSpec.describe Teckel::Operation do
  context "default settings" do
    shared_examples "operation with default settings" do |operation|
      subject { operation }

      it "with no settings" do
        expect(subject.call).to eq(:default_value)
      end

      it "with settings" do
        expect(subject.with(:injected_value).call).to eq(:injected_value)
      end
    end

    describe "with default constructor and clever Settings class" do
      it_behaves_like(
        "operation with default settings",
        Class.new(TeckelOperationDefaultSettings::BaseOperation) do
          settings(Class.new do
            def initialize(injected = nil)
              @injected = injected
            end

            def injected
              @injected || :default_value
            end

            class << self
              alias :[] :new # make us respond to the default constructor
            end
          end)

          default_settings!
        end
      )
    end

    describe "with custom constructor and clever Settings class" do
      it_behaves_like(
        "operation with default settings",
        Class.new(TeckelOperationDefaultSettings::BaseOperation) do
          settings(Class.new do
            def initialize(injected = nil)
              @injected = injected
            end

            def injected
              @injected || :default_value
            end
          end)

          settings_constructor :new
          default_settings!
        end
      )
    end

    describe "with default constructor and simple Settings class" do
      it_behaves_like(
        "operation with default settings",
        Class.new(TeckelOperationDefaultSettings::BaseOperation) do
          settings Struct.new(:injected)

          default_settings! -> { settings.new(:default_value) }
        end
      )

      it_behaves_like(
        "operation with default settings",
        Class.new(TeckelOperationDefaultSettings::BaseOperation) do
          settings Struct.new(:injected)

          default_settings!(:default_value)
        end
      )
    end
  end
end
