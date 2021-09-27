# frozen_string_literal: true

require "ostruct"

RSpec.describe Teckel::Operation do
  let(:operation) do
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

  let(:blank_operation) do
    Class.new do
      include Teckel::Operation
    end
  end

  describe ".settings" do
    specify "no settings" do
      expect(operation.settings).to eq(Teckel::Contracts::None)
      expect(operation.settings_constructor).to eq(Teckel::Contracts::None.method(:new))
    end

    specify "with settings klass" do
      settings_klass = Struct.new(:name)
      operation.settings(settings_klass)
      expect(operation.settings).to eq(settings_klass)
    end

    specify "without settings class, with settings constructor as proc" do
      settings_const = if RUBY_VERSION < '2.6.0'
        ->(sets) { sets.map { |k, v| [k.to_s, v.to_i] }.to_h }
      else
        ->(sets) { sets.to_h { |k, v| [k.to_s, v.to_i] } }
      end

      operation.settings_constructor(settings_const)

      expect(operation.settings).to eq(Teckel::Contracts::None)
      expect(operation.settings_constructor).to eq(settings_const)

      runner = operation.with(key: "1")
      expect(runner).to be_a(Teckel::Operation::Runner)
      expect(runner.settings).to eq({ "key" => 1 })
    end

    specify "with settings class, with settings constructor as symbol" do
      settings_klass = Struct.new(:name) do
        def self.make_one(opts)
          new(opts[:name])
        end
      end

      operation.settings(settings_klass)
      operation.settings_constructor(:make_one)

      expect(operation.settings).to eq(settings_klass)
      expect(operation.settings_constructor).to eq(settings_klass.method(:make_one))

      runner = operation.with(name: "value")
      expect(runner).to be_a(Teckel::Operation::Runner)
      expect(runner.settings).to be_a(settings_klass)
      expect(runner.settings.name).to eq("value")
    end

    specify "with settings class as constant" do
      settings_klass = Struct.new(:name)
      operation.const_set(:Settings, settings_klass)

      expect(operation.settings).to eq(settings_klass)
      expect(operation.settings_constructor).to eq(settings_klass.method(:[]))
    end
  end

  describe ".default_settings" do
    specify "no default_settings" do
      expect(operation.default_settings).to be_nil
      expect(operation.runner).to receive(:new).with(operation).and_call_original

      operation.call
    end

    specify "default_settings!() with no default_settings" do
      operation.default_settings!
      expect(operation.default_settings).to be_a(Proc)

      expect(operation.default_settings).to receive(:call).with(no_args).and_wrap_original do |original_method, *args, &block|
        settings = original_method.call(*args, &block)
        expect(settings).to be_nil
        expect(operation.runner).to receive(:new).with(operation, settings).and_call_original
        settings
      end

      operation.call
    end

    specify "default_settings!() with default_settings" do
      settings_klass = Struct.new(:name)

      operation.settings(settings_klass)
      operation.default_settings!

      expect(operation.default_settings).to be_a(Proc)

      expect(operation.default_settings).to receive(:call).with(no_args).and_wrap_original do |original_method, *args, &block|
        settings = original_method.call(*args, &block)
        expect(settings).to be_a(settings_klass).and have_attributes(name: nil)
        expect(operation.runner).to receive(:new).with(operation, settings).and_call_original
        settings
      end

      operation.call
    end

    specify "default_settings!(arg) with default_settings" do
      settings_klass = Struct.new(:name)

      operation.settings(settings_klass)
      operation.default_settings!("Bob")

      expect(operation.default_settings).to be_a(Proc)

      expect(operation.default_settings).to receive(:call).with(no_args).and_wrap_original do |original_method, *args, &block|
        settings = original_method.call(*args, &block)
        expect(settings).to be_a(settings_klass).and have_attributes(name: "Bob")
        expect(operation.runner).to receive(:new).with(operation, settings).and_call_original
        settings
      end

      expect(operation.call).to be_a(Struct).and have_attributes(name: "Bob")
    end
  end

  %i[input output error].each do |meth|
    describe ".#{meth}" do
      specify "missing .#{meth} config raises MissingConfigError" do
        expect {
          blank_operation.public_send(meth)
        }.to raise_error(Teckel::MissingConfigError, "Missing #{meth} config for #{blank_operation}")
      end
    end

    describe ".#{meth}_constructor" do
      specify "missing .#{meth}_constructor config raises MissingConfigError for missing #{meth}" do
        expect {
          blank_operation.public_send(:"#{meth}_constructor")
        }.to raise_error(Teckel::MissingConfigError, "Missing #{meth} config for #{blank_operation}")
      end
    end
  end

  specify "default settings config" do
    expect(blank_operation.settings).to eq(Teckel::Contracts::None)
  end

  specify "default settings_constructor" do
    expect(blank_operation.settings_constructor).to eq(Teckel::Contracts::None.method(:[]))
  end

  specify "default settings_constructor with settings config set" do
    settings_klass = Struct.new(:name)
    blank_operation.settings(settings_klass)

    expect(blank_operation.settings_constructor).to eq(settings_klass.method(:[]))
  end

  specify "unsupported constructor method" do
    blank_operation.settings(Class.new)
    expect {
      blank_operation.settings_constructor(:nope)
    }.to raise_error(Teckel::MissingConfigError, "Missing settings_constructor config for #{blank_operation}")

    expect {
      blank_operation.settings_constructor
    }.to raise_error(Teckel::MissingConfigError, "Missing settings_constructor config for #{blank_operation}")
  end

  describe "result" do
    specify "default result config" do
      expect(blank_operation.result).to eq(Teckel::Operation::ValueResult)
    end

    specify "default result_constructor" do
      expect(blank_operation.result_constructor).to eq(Teckel::Operation::ValueResult.method(:[]))
    end

    specify "default result_constructor with settings config set" do
      result_klass = OpenStruct.new
      blank_operation.result(result_klass)

      expect(blank_operation.result_constructor).to eq(result_klass.method(:[]))
    end

    specify "unsupported constructor method" do
      blank_operation.result(Class.new)
      expect {
        blank_operation.result_constructor(:nope)
      }.to raise_error(Teckel::MissingConfigError, "Missing result_constructor config for #{blank_operation}")

      expect {
        blank_operation.result_constructor
      }.to raise_error(Teckel::MissingConfigError, "Missing result_constructor config for #{blank_operation}")
    end

    specify "with result class as constant" do
      result_klass = OpenStruct.new
      blank_operation.const_set(:Result, result_klass)

      expect(blank_operation.result).to eq(result_klass)
      expect(blank_operation.result_constructor).to eq(result_klass.method(:[]))
    end
  end

  describe "result!" do
    specify "default result config" do
      blank_operation.result!
      expect(blank_operation.result).to eq(Teckel::Operation::Result)
    end
  end
end
