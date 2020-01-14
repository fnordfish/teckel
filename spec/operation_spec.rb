# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

RSpec.describe Teckel::Operation do
  context "predefined classes" do
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
            user
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
    module TeckelOperationAnnonClassesTest
      class CreateUser
        include ::Teckel::Operation

        input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)
        output Types.Instance(User)
        error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))

        # @param [Hash<name: String, age: Integer>]
        # @return [User,Hash<message: String, errors: [Hash]>]
        def call(input)
          user = User.new(name: input[:name], age: input[:age])
          if user.save
            user
          else
            fail!(message: "Could not save User", errors: user.errors)
          end
        end
      end
    end

    specify "output" do
      expect(TeckelOperationAnnonClassesTest::CreateUser.call(name: "Bob", age: 23)).to be_a(User)
    end

    specify "errors" do
      expect(TeckelOperationAnnonClassesTest::CreateUser.call(name: "Bob", age: 10)).to eq(message: "Could not save User", errors: [{ age: "underage" }])
    end
  end

  context "generated output" do
    module TeckelOperationGeneratedOutputTest
      class MyOperation
        include ::Teckel::Operation

        input none
        output Struct.new(:some_key)
        output_constructor ->(data) { output.new(*data.values_at(*output.members)) } # ruby 2.4 way for `keyword_init: true`
        error none

        def call(_input)
          { some_key: "some_value" }
        end
      end
    end

    specify "result" do
      result = TeckelOperationGeneratedOutputTest::MyOperation.call
      expect(result).to be_a(Struct)
      expect(result.some_key).to eq("some_value")
    end
  end

  context "None in, out, err" do
    module TeckelOperationNoneDataTest
      class MyOperation
        include ::Teckel::Operation

        class << self
          attr_accessor :fail_it
          attr_accessor :fail_data
          attr_accessor :success_it
          attr_accessor :success_data
        end

        input none
        output none
        error none

        def call(_input)
          if self.class.fail_it
            if self.class.fail_data
              fail!(self.class.fail_data)
            else
              fail!
            end
          elsif self.class.success_it
            if self.class.success_data
              success!(self.class.success_data)
            else
              success!
            end
          else
            self.class.success_data || nil
          end
        end
      end
    end

    after {
      TeckelOperationNoneDataTest::MyOperation.fail_it = nil
      TeckelOperationNoneDataTest::MyOperation.fail_data = nil
      TeckelOperationNoneDataTest::MyOperation.success_it = nil
      TeckelOperationNoneDataTest::MyOperation.success_data = nil
    }

    it "raises error when called with input data" do
      expect {
        TeckelOperationNoneDataTest::MyOperation.call("stuff")
      }.to raise_error(ArgumentError)
    end

    it "raises error when fail! with data" do
      TeckelOperationNoneDataTest::MyOperation.fail_it = true
      TeckelOperationNoneDataTest::MyOperation.fail_data = "stuff"
      expect {
        TeckelOperationNoneDataTest::MyOperation.call
      }.to raise_error(ArgumentError)
    end

    it "returns nil as failure result when fail! without arguments" do
      TeckelOperationNoneDataTest::MyOperation.fail_it = true
      expect(TeckelOperationNoneDataTest::MyOperation.call).to be_nil
    end

    it "raises error when success! with data" do
      TeckelOperationNoneDataTest::MyOperation.success_it = true
      TeckelOperationNoneDataTest::MyOperation.success_data = "stuff"
      expect {
        TeckelOperationNoneDataTest::MyOperation.call
      }.to raise_error(ArgumentError)
    end

    it "returns nil as success result when success! without arguments" do
      TeckelOperationNoneDataTest::MyOperation.success_it = true
      expect(TeckelOperationNoneDataTest::MyOperation.call).to be_nil
    end

    it "raises error when returning data" do
      TeckelOperationNoneDataTest::MyOperation.success_it = false
      TeckelOperationNoneDataTest::MyOperation.success_data = "stuff"
      expect {
        TeckelOperationNoneDataTest::MyOperation.call
      }.to raise_error(ArgumentError)
    end

    it "returns nil as success result when returning nil" do
      expect(TeckelOperationNoneDataTest::MyOperation.call).to be_nil
    end
  end

  describe "#finalize!" do
    let(:frozen_error) do
      # different ruby versions raise different errors
      defined?(FrozenError) ? FrozenError : RuntimeError
    end

    module TeckelOperationFinalizeTest
      class MyOperation
        include ::Teckel::Operation

        input Struct.new(:input_data)
        output Struct.new(:output_data)

        def call(input)
          success!(input.input_data * 2)
        end
      end
    end

    it "fails b/c error config is missing" do
      my_operation = TeckelOperationFinalizeTest::MyOperation.dup
      expect {
        my_operation.finalize!
      }.to raise_error(Teckel::MissingConfigError, "Missing error config for #{my_operation}")
    end

    it "is frozen" do
      my_operation = TeckelOperationFinalizeTest::MyOperation.dup
      my_operation.error Struct.new(:error)
      my_operation.finalize!
      expect(my_operation).to be_frozen
    end

    specify "#dup" do
      my_operation = TeckelOperationFinalizeTest::MyOperation.dup
      my_operation.error Struct.new(:error)

      expect(my_operation.dup).not_to be_frozen
      expect(my_operation.finalize!.dup).not_to be_frozen
    end

    specify "#clone" do
      my_operation = TeckelOperationFinalizeTest::MyOperation.dup
      my_operation.error Struct.new(:error)

      expect(my_operation.clone).not_to be_frozen
      expect(my_operation.finalize!.clone).to be_frozen
    end

    it "rejects any config changes" do
      my_operation = TeckelOperationFinalizeTest::MyOperation.dup
      my_operation.error Struct.new(:error)

      # this still works:
      my_operation.class_eval do
        def call(input)
          success!(input.input_data * 3)
        end
      end

      result = my_operation.call("test")
      expect(result.output_data).to eq("testtesttest")

      # no more after finalize!
      my_operation.finalize!
      expect {
        my_operation.class_eval do
          def call(input)
            success!(input.input_data * 4)
          end
        end
      }.to raise_error(frozen_error)
    end

    it "runs" do
      my_operation = TeckelOperationFinalizeTest::MyOperation.dup
      my_operation.error Struct.new(:error)
      my_operation.finalize!

      result = my_operation.call("test")
      expect(result.output_data).to eq("testtest")
    end
  end
end
