# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

RSpec.describe Waldi::Operation do
  context "predefined classes" do
    module WaldiOperationPredefinedClassesTest
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
        include Waldi::Operation

        input  CreateUserInput
        output CreateUserOutput
        error  CreateUserError

        def call(input)
          user = User.new(**input.attributes)
          if user.safe
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
      expect(WaldiOperationPredefinedClassesTest::CreateUser.input).to eq(WaldiOperationPredefinedClassesTest::CreateUserInput)
    end

    specify "Output" do
      expect(WaldiOperationPredefinedClassesTest::CreateUser.output).to eq(WaldiOperationPredefinedClassesTest::CreateUserOutput)
    end

    specify "Error" do
      expect(WaldiOperationPredefinedClassesTest::CreateUser.error).to eq(WaldiOperationPredefinedClassesTest::CreateUserError)
    end

    context "success" do
      specify do
        result = WaldiOperationPredefinedClassesTest::CreateUser.call(name: "Bob", age: 23)
        expect(result).to be_a(User)
      end
    end

    context "error" do
      specify do
        result = WaldiOperationPredefinedClassesTest::CreateUser.call(name: "Bob", age: 7)
        expect(result).to be_a(WaldiOperationPredefinedClassesTest::CreateUserError)
        expect(result).to have_attributes(
          message: "Could not create User",
          status_code: 400,
          meta: { validation: [{ age: "underage" }] }
        )
      end
    end
  end

  context "inline classes" do
    module WaldiOperationInlineClassesTest
      class CreateUser
        include Waldi::Operation

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
          if user.safe
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
      expect(WaldiOperationInlineClassesTest::CreateUser.input).to be <= Dry::Struct
    end

    specify "Output" do
      expect(WaldiOperationInlineClassesTest::CreateUser.output).to be_a Dry::Types::Constrained
    end

    specify "Error" do
      expect(WaldiOperationInlineClassesTest::CreateUser.error).to be <= Dry::Struct
    end

    context "success" do
      specify do
        result = WaldiOperationInlineClassesTest::CreateUser.call(name: "Bob", age: 23)
        expect(result).to be_a(User)
      end
    end

    context "error" do
      specify do
        result = WaldiOperationInlineClassesTest::CreateUser.call(name: "Bob", age: 7)
        expect(result).to have_attributes(
          message: "Could not create User",
          status_code: 400,
          meta: { validation: [{ age: "underage" }] }
        )
      end
    end
  end

  context "annon classes" do
    module WaldiOperationAnnonClassesTest
      class CreateUser
        include ::Waldi::Operation

        input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)
        output Types.Instance(User)
        error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))

        # @param [Hash<name: String, age: Integer>]
        # @return [User | Hash<message: String, errors: [Hash]>]
        def call(input)
          user = User.new(name: input[:name], age: input[:age])
          if user.safe
            user
          else
            fail!(message: "Could not safe User", errors: user.errors)
          end
        end
      end
    end

    specify "output" do
      expect(WaldiOperationAnnonClassesTest::CreateUser.call(name: "Bob", age: 23)).to be_a(User)
    end

    specify "errors" do
      expect(WaldiOperationAnnonClassesTest::CreateUser.call(name: "Bob", age: 10)).to eq(message: "Could not safe User", errors: [{ age: "underage" }])
    end
  end
end
