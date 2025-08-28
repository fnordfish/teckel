# frozen_string_literal: true

@warning = Warning[:experimental]
Warning[:experimental] = false

RSpec.describe "Ruby 3,0 pattern matches for Result and Chain" do
  describe "Operation Result" do
    context "success" do
      specify "pattern matching with array" do
        r = Teckel::Operation::Result[{ friend: "a friend", user: "bob" }, true]
        successful, value, friend, user, rest = nil
        expect {
          r => [successful, value]
        }.not_to raise_error
        expect(successful).to be(true)
        expect(value).to eq({ friend: "a friend", user: "bob" })

        expect {
          r => [successful, { friend: friend, user: user, **rest }]
        }.not_to raise_error

        expect(successful).to be(true)
        expect(friend).to eq("a friend")
        expect(user).to eq("bob")
        expect(rest).to eq({})
      end

      specify "pattern matching with hash" do
        r = Teckel::Operation::Result[{ friend: "a friend", user: "bob" }, true]
        successful, value, friend, user, rest = nil
        expect {
          r => { success: successful, value: value }
        }.not_to raise_error
        expect(successful).to be(true)
        expect(value).to eq({ friend: "a friend", user: "bob" })

        expect {
          r => { success: successful, value: { friend: friend, user: user, **rest }}
        }.not_to raise_error
        expect(successful).to be(true)
        expect(value).to eq({ friend: "a friend", user: "bob" })
        expect(friend).to eq("a friend")
        expect(user).to eq("bob")
        expect(rest).to eq({})
      end
    end

    context "failure" do
      specify "pattern matching with keys" do
        result =
          TeckelChainPatternMatchingTest::AddFriend.
          with(befriend: :fail).
          call(User.new(name: "bob", age: 23))

        x =
          case result
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
        result =
          TeckelChainPatternMatchingTest::AddFriend.
          with(befriend: :fail).
          call(User.new(name: "bob", age: 23))

        x =
          case result
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

  describe "Chain Result" do
    context "success" do
      specify "pattern matching with array" do
        r = Teckel::Chain::Result[{ friend: "a friend", user: "bob" }, true, :some_step]
        successful, step_name, value, friend, user, rest = nil
        expect {
          r => [successful, step_name, value]
        }.not_to raise_error
        expect(successful).to be(true)
        expect(step_name).to eq("some_step")
        expect(value).to eq({ friend: "a friend", user: "bob" })

        expect {
          r => [successful, step_name, { friend: friend, user: user, **rest }]
        }.not_to raise_error

        expect(successful).to be(true)
        expect(step_name).to eq("some_step")
        expect(friend).to eq("a friend")
        expect(user).to eq("bob")
        expect(rest).to eq({})
      end

      specify "pattern matching with hash" do
        r = Teckel::Chain::Result[{ friend: "a friend", user: "bob" }, true, :some_step]
        successful, step_name, value, friend, user, rest = nil
        expect {
          r => { success: successful, step: step_name, value: value }
        }.not_to raise_error
        expect(successful).to be(true)
        expect(step_name).to eq("some_step")
        expect(value).to eq({ friend: "a friend", user: "bob" })

        expect {
          r => { success: successful, step: step_name, value: { friend: friend, user: user, **rest }}
        }.not_to raise_error
        expect(successful).to be(true)
        expect(step_name).to eq("some_step")
        expect(value).to eq({ friend: "a friend", user: "bob" })
        expect(friend).to eq("a friend")
        expect(user).to eq("bob")
        expect(rest).to eq({})
      end
    end
  end
end

Warning[:experimental] = @warning
