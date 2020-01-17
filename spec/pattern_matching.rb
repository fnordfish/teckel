# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

RSpec.describe "Ruby 2.7 pattern matches for Result and Chain" do
  module TeckelChainPatternMatchingTest
    class CreateUser
      include ::Teckel::Operation::Results

      input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer.optional)
      output Types.Instance(User)
      error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))

      # @param [Hash<name: String, age: Integer>]
      # @return [User,Hash<message: String, errors: [Hash]>]
      def call(input)
        user = User.new(name: input[:name], age: input[:age])
        if user.save
          success!(user)
        else
          fail!(message: "Could not save User", errors: user.errors)
        end
      end
    end

    class LogUser
      include ::Teckel::Operation::Results

      input Types.Instance(User)
      error none
      output input

      def call(usr)
        Logger.new(File::NULL).info("User #{usr.name} created")
        usr
      end
    end

    class AddFriend
      class << self
        attr_accessor :fail_befriend
      end

      include ::Teckel::Operation::Results

      input Types.Instance(User)
      output Types::Hash.schema(user: Types.Instance(User), friend: Types.Instance(User))
      error  Types::Hash.schema(message: Types::String)

      def call(user)
        if self.class.fail_befriend
          fail!(message: "Did not find a friend.")
        else
          { user: user, friend: User.new(name: "A friend", age: 42) }
        end
      end
    end

    class Chain
      include Teckel::Chain

      step :create, CreateUser
      step :log, LogUser
      step :befriend, AddFriend
    end
  end

  describe "Result" do
    context "success" do
      specify "pattern matching with keys" do
        x =
          case TeckelChainPatternMatchingTest::AddFriend.call(User.new(name: "bob", age: 23))
          in { success: false, value: value }
            ["Failed", value]
          in { success: true, value: value }
            ["Success result", value]
          else
            raise "Unexpected Result"
          end

        expect(x).to contain_exactly("Success result", hash_including(:friend, :user))
      end
    end

    context "failure" do
      before { TeckelChainPatternMatchingTest::AddFriend.fail_befriend = true }
      after { TeckelChainPatternMatchingTest::AddFriend.fail_befriend = nil }

      specify "pattern matching with keys" do
        x =
          case TeckelChainPatternMatchingTest::AddFriend.call(User.new(name: "bob", age: 23))
          in { success: false, value: value }
            ["Failed", value]
          in { success: true, value: value }
            ["Success result", value]
          else
            raise "Unexpected Result"
          end

        expect(x).to contain_exactly("Failed", hash_including(:message))
      end

      specify "pattern matching array" do
        x =
          case TeckelChainPatternMatchingTest::AddFriend.call(User.new(name: "bob", age: 23))
          in [false, value]
            ["Failed", value]
          in [true, value]
            ["Success result", value]
          else
            raise "Unexpected Result"
          end
        expect(x).to contain_exactly("Failed", hash_including(:message))
      end
    end
  end

  describe "Chain" do
    context "success" do
      before { TeckelChainPatternMatchingTest::AddFriend.fail_befriend = false }
      specify "pattern matching with keys" do
        x =
          case TeckelChainPatternMatchingTest::Chain.call(name: "Bob", age: 23)
          in { success: false, step: :befriend, value: value }
              ["Failed", value]
          in { success: true, value: value }
            ["Success result", value]
          else
            raise "Unexpected Result"
          end
        expect(x).to contain_exactly("Success result", hash_including(:friend, :user))
      end

      specify "pattern matching array" do
        x =
          case TeckelChainPatternMatchingTest::Chain.call(name: "Bob", age: 23)
          in [false, :befriend, value]
              "Failed in befriend with #{value}"
          in [true, value]
            "Success result"
          end
        expect(x).to eq("Success result")
      end
    end

    context "failure" do
      before { TeckelChainPatternMatchingTest::AddFriend.fail_befriend = true }
      after { TeckelChainPatternMatchingTest::AddFriend.fail_befriend = nil }

      specify "pattern matching with keys" do
        x =
          case TeckelChainPatternMatchingTest::Chain.call(name: "Bob", age: 23)
          in { success: false, step: :befriend, value: value }
              "Failed in befriend with #{value}"
          in { success: true, value: value }
            "Success result"
          end
        expect(x).to eq("Failed in befriend with #{ {message: "Did not find a friend."} }")
      end

      specify "pattern matching array" do
        x =
          case TeckelChainPatternMatchingTest::Chain.call(name: "Bob", age: 23)
          in [false, :befriend, value]
              "Failed in befriend with #{value}"
          in [true, value]
            "Success result"
          end
        expect(x).to eq("Failed in befriend with #{ {message: "Did not find a friend."} }")
      end
    end
  end
end
