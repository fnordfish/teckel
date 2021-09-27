# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

module TeckelOperationPredefinedClassesTest
  class CreateUserInput < Dry::Struct
    attribute :name, Types::String
    attribute :age, Types::Coercible::Integer
  end

  CreateUserOutput = Types.Instance(User)

  class CreateUserError < Dry::Struct
    attribute :message, Types::String
    attribute :status_code, Types::Integer
    attribute :meta, Types::Hash.optional
  end

  class CreateUser
    include Teckel::Operation

    input  CreateUserInput
    output CreateUserOutput
    error  CreateUserError

    def call(input)
      user = User.new(**input.attributes)
      if user.save
        success!(user)
      else
        fail!(
          message: "Could not create User",
          status_code: 400,
          meta: { validation: user.errors }
        )
      end
    end
  end
end

module TeckelOperationInlineClassesTest
  class CreateUser
    include Teckel::Operation

    class Input < Dry::Struct
      attribute :name, Types::String
      attribute :age, Types::Coercible::Integer
    end

    Output = Types.Instance(User)

    class Error < Dry::Struct
      attribute :message, Types::String
      attribute :status_code, Types::Integer
      attribute :meta, Types::Hash.optional
    end

    def call(input)
      user = User.new(**input.attributes)
      if user.save
        success!(user)
      else
        fail!(
          message: "Could not create User",
          status_code: 400,
          meta: { validation: user.errors }
        )
      end
    end
  end
end

module TeckelOperationAnnonClassesTest
  class CreateUser
    include ::Teckel::Operation

    input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)
    output Types.Instance(User)
    error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))

    def call(input)
      user = User.new(name: input[:name], age: input[:age])
      if user.save
        success!(user)
      else
        fail!(message: "Could not save User", errors: user.errors)
      end
    end
  end
end

module TeckelOperationKeywordContracts
  class MyOperation
    include Teckel::Operation

    class Input
      def initialize(name:, age:)
        @name, @age = name, age
      end
      attr_reader :name, :age
    end

    input_constructor ->(data) { Input.new(**data) }

    Output = ::User

    class Error
      def initialize(message, errors)
        @message, @errors = message, errors
      end
      attr_reader :message, :errors
    end
    error_constructor :new

    def call(input)
      user = ::User.new(name: input.name, age: input.age)
      if user.save
        success!(user)
      else
        fail!(message: "Could not save User", errors: user.errors)
      end
    end
  end
end

module TeckelOperationCreateUserSplatInit
  class MyOperation
    include Teckel::Operation

    input Struct.new(:name, :age)
    input_constructor ->(data) { self.class.input.new(*data) }

    Output = ::User

    class Error
      def initialize(message, errors)
        @message, @errors = message, errors
      end
      attr_reader :message, :errors
    end
    error_constructor :new

    def call(input)
      user = ::User.new(name: input.name, age: input.age)
      if user.save
        success!(user)
      else
        fail!(message: "Could not save User", errors: user.errors)
      end
    end
  end
end

module TeckelOperationGeneratedOutputTest
  class MyOperation
    include ::Teckel::Operation

    input none
    output Struct.new(:some_key)
    output_constructor ->(data) { output.new(*data.values_at(*output.members)) } # ruby 2.4 way for `keyword_init: true`
    error none

    def call(_input)
      success!(some_key: "some_value")
    end
  end
end

module TeckelOperationNoSettingsTest
  class MyOperation
    include ::Teckel::Operation

    input none
    output none
    error none

    def call(_input); end
  end
  MyOperation.finalize!
end

module TeckelOperationNoneDataTest
  class MyOperation
    include ::Teckel::Operation

    settings Struct.new(:fail_it, :fail_data, :success_it, :success_data)
    settings_constructor ->(data) { settings.new(*data.values_at(*settings.members)) }

    input none
    output none
    error none

    def call(_input)
      if settings&.fail_it
        if settings&.fail_data
          fail!(settings.fail_data)
        else
          fail!
        end
      elsif settings&.success_it
        if settings&.success_data
          success!(settings.success_data)
        else
          success!
        end
      else
        settings&.success_data
      end
    end
  end
end

module TeckelOperationInjectSettingsTest
  class MyOperation
    include ::Teckel::Operation

    settings Struct.new(:injected)
    settings_constructor ->(data) { settings.new(*data.values_at(*settings.members)) }

    input none
    output Array
    error none

    def call(_input)
      success!((settings&.injected || []) << :operation_data)
    end
  end
end

RSpec.describe Teckel::Operation do
  context "predefined classes" do
    specify "Input" do
      expect(TeckelOperationPredefinedClassesTest::CreateUser.input).to eq(TeckelOperationPredefinedClassesTest::CreateUserInput)
    end

    specify "Output" do
      expect(TeckelOperationPredefinedClassesTest::CreateUser.output).to eq(TeckelOperationPredefinedClassesTest::CreateUserOutput)
    end

    specify "Error" do
      expect(TeckelOperationPredefinedClassesTest::CreateUser.error).to eq(TeckelOperationPredefinedClassesTest::CreateUserError)
    end

    context "success" do
      specify do
        result = TeckelOperationPredefinedClassesTest::CreateUser.call(name: "Bob", age: 23)
        expect(result).to be_a(User)
      end
    end

    context "error" do
      specify do
        result = TeckelOperationPredefinedClassesTest::CreateUser.call(name: "Bob", age: 7)
        expect(result).to be_a(TeckelOperationPredefinedClassesTest::CreateUserError)
        expect(result).to have_attributes(
          message: "Could not create User",
          status_code: 400,
          meta: { validation: [{ age: "underage" }] }
        )
      end
    end
  end

  context "inline classes" do
    specify "Input" do
      expect(TeckelOperationInlineClassesTest::CreateUser.input).to be <= Dry::Struct
    end

    specify "Output" do
      expect(TeckelOperationInlineClassesTest::CreateUser.output).to be_a Dry::Types::Constrained
    end

    specify "Error" do
      expect(TeckelOperationInlineClassesTest::CreateUser.error).to be <= Dry::Struct
    end

    context "success" do
      specify do
        result = TeckelOperationInlineClassesTest::CreateUser.call(name: "Bob", age: 23)
        expect(result).to be_a(User)
      end
    end

    context "error" do
      specify do
        result = TeckelOperationInlineClassesTest::CreateUser.call(name: "Bob", age: 7)
        expect(result).to have_attributes(
          message: "Could not create User",
          status_code: 400,
          meta: { validation: [{ age: "underage" }] }
        )
      end
    end
  end

  context "annon classes" do
    specify "output" do
      expect(TeckelOperationAnnonClassesTest::CreateUser.call(name: "Bob", age: 23)).to be_a(User)
    end

    specify "errors" do
      expect(TeckelOperationAnnonClassesTest::CreateUser.call(name: "Bob", age: 10)).to eq(message: "Could not save User", errors: [{ age: "underage" }])
    end
  end

  context "keyword contracts" do
    specify do
      expect(TeckelOperationKeywordContracts::MyOperation.call(name: "Bob", age: 23)).to be_a(User)
    end
  end

  context "splat contracts" do
    specify do
      expect(TeckelOperationCreateUserSplatInit::MyOperation.call(["Bob", 23])).to be_a(User)
    end
  end

  context "generated output" do
    specify "result" do
      result = TeckelOperationGeneratedOutputTest::MyOperation.call
      expect(result).to be_a(Struct)
      expect(result.some_key).to eq("some_value")
    end
  end

  context "inject settings" do
    it "settings in operation instances are nil by default" do
      op = TeckelOperationInjectSettingsTest::MyOperation.new
      expect(op.settings).to be_nil
    end

    it "uses injected data" do
      result = TeckelOperationInjectSettingsTest::MyOperation.
        with(injected: [:stuff]).
        call

      expect(result).to eq([:stuff, :operation_data])

      expect(TeckelOperationInjectSettingsTest::MyOperation.call).to eq([:operation_data])
    end

    specify "calling `with` multiple times raises an error" do
      op = TeckelOperationInjectSettingsTest::MyOperation.with(injected: :stuff1)

      expect {
        op.with(more: :stuff2)
      }.to raise_error(Teckel::Error, "Operation already has settings assigned.")
    end
  end

  context "operation with no settings" do
    it "uses None as default settings class" do
      expect(TeckelOperationNoSettingsTest::MyOperation.settings).to eq(Teckel::Contracts::None)
      expect(TeckelOperationNoSettingsTest::MyOperation.new.settings).to be_nil
    end

    it "raises error when trying to set settings" do
      expect {
        TeckelOperationNoSettingsTest::MyOperation.with(any: :thing)
      }.to raise_error(ArgumentError, "None called with arguments")
    end
  end

  context "None in, out, err" do
    let(:operation) { TeckelOperationNoneDataTest::MyOperation }

    it "raises error when called with input data" do
      expect { operation.call("stuff") }.to raise_error(ArgumentError)
    end

    it "raises error when fail! with data" do
      expect {
        operation.with(fail_it: true, fail_data: "stuff").call
      }.to raise_error(ArgumentError)
    end

    it "returns nil as failure result when fail! without arguments" do
      expect(operation.with(fail_it: true).call).to be_nil
    end

    it "raises error when success! with data" do
      expect {
        operation.with(success_it: true, success_data: "stuff").call
      }.to raise_error(ArgumentError)
    end

    it "returns nil as success result when success! without arguments" do
      expect(operation.with(success_it: true).call).to be_nil
    end

    it "returns nil as success result when returning nil" do
      expect(operation.call).to be_nil
    end
  end

  describe "#finalize!" do
    let(:frozen_error) do
      # different ruby versions raise different errors
      defined?(FrozenError) ? FrozenError : RuntimeError
    end

    subject do
      Class.new do
        include ::Teckel::Operation

        input Struct.new(:input_data)
        output Struct.new(:output_data)

        def call(input)
          success!(input.input_data * 2)
        end
      end
    end

    it "fails b/c error config is missing" do
      expect {
        subject.finalize!
      }.to raise_error(Teckel::MissingConfigError, "Missing error config for #{subject}")
    end

    specify "#dup" do
      new_operation = subject.dup
      new_operation.error Struct.new(:error)
      expect { new_operation.finalize! }.to_not raise_error

      expect {
        subject.finalize!
      }.to raise_error(Teckel::MissingConfigError, "Missing error config for #{subject}")
    end

    specify "#clone" do
      new_operation = subject.clone
      new_operation.error Struct.new(:error)
      expect { new_operation.finalize! }.to_not raise_error

      expect {
        subject.finalize!
      }.to raise_error(Teckel::MissingConfigError, "Missing error config for #{subject}")
    end

    it "rejects any config changes" do
      subject.error Struct.new(:error)
      expect { subject.finalize! }.to_not raise_error

      # no more after finalize!
      subject.finalize!

      expect {
        subject.error Struct.new(:other_error)
      }.to raise_error(Teckel::FrozenConfigError, "Configuration error is already set")
    end

    it "runs" do
      subject.error Struct.new(:error)
      subject.finalize!

      result = subject.call("test")
      expect(result.output_data).to eq("testtest")
    end

    it "accepts mocks" do
      subject.error Struct.new(:error)
      subject.finalize!

      allow(subject).to receive(:call) { :mocked }
      expect(subject.call).to eq(:mocked)
    end
  end

  describe "overwriting configs is not allowed" do
    it "raises" do
      expect {
        Class.new do
          include ::Teckel::Operation
          input none
          input Struct.new(:name)
        end
      }.to raise_error Teckel::FrozenConfigError, "Configuration input is already set"
    end
  end
end
