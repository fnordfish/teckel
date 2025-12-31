# frozen_string_literal: true

require "support/dry_base"
require "support/fake_models"

module TeckelChainTest
  class CreateUser
    include ::Teckel::Operation

    result!

    input Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer.optional)
    output Types.Instance(User)
    error Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))

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
    include ::Teckel::Operation

    result!

    input Types.Instance(User)
    error none
    output input

    def call(usr)
      Logger.new(File::NULL).info("User #{usr.name} created")
      success! usr
    end
  end

  class AddFriend
    include ::Teckel::Operation

    result!

    settings Struct.new(:fail_befriend)

    input Types.Instance(User)
    output Types::Hash.schema(user: Types.Instance(User), friend: Types.Instance(User))
    error Types::Hash.schema(message: Types::String)

    def call(user)
      if settings&.fail_befriend
        fail!(message: "Did not find a friend.")
      else
        success! user: user, friend: User.new(name: "A friend", age: 42)
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

RSpec.describe Teckel::Chain do
  let(:frozen_error) do
    # different ruby versions raise different errors
    defined?(FrozenError) ? FrozenError : RuntimeError
  end

  it "Chain input points to first step input" do
    expect(TeckelChainTest::Chain.input).to eq(TeckelChainTest::CreateUser.input)
  end

  it "Chain output points to last steps output" do
    expect(TeckelChainTest::Chain.output).to eq(TeckelChainTest::AddFriend.output)
  end

  it "Chain errors maps all step errors" do
    expect(TeckelChainTest::Chain.errors).to eq([
      TeckelChainTest::CreateUser.error,
      Teckel::Contracts::None,
      TeckelChainTest::AddFriend.error
    ])
  end

  context "success" do
    it "result matches" do
      result = TeckelChainTest::Chain
        .with(befriend: nil)
        .call(name: "Bob", age: 23)

      expect(result.success).to include(user: kind_of(User), friend: kind_of(User))
    end
  end

  context "failure" do
    it "returns a Result for invalid input" do
      result = TeckelChainTest::Chain
        .with(befriend: :fail)
        .call(name: "Bob", age: 0)

      expect(result).to be_a(Teckel::Chain::Result)
      expect(result).to be_failure
      expect(result.step).to eq(:create)
      expect(result.value).to eq(errors: [{age: "underage"}], message: "Could not save User")
    end

    it "returns a Result for failed step" do
      result = TeckelChainTest::Chain
        .with(befriend: :fail)
        .call(name: "Bob", age: 23)

      expect(result).to be_a(Teckel::Chain::Result)
      expect(result).to be_failure
      expect(result.step).to eq(:befriend)
      expect(result.value).to eq(message: "Did not find a friend.")
    end
  end

  describe "#finalize!" do
    subject { TeckelChainTest::Chain.dup }

    it "freezes the Chain class and operation classes" do
      subject.finalize!

      steps = subject.steps
      expect(steps).to be_frozen
      expect(steps).to all be_frozen
    end

    it "disallows adding new steps" do
      subject.class_eval do
        step :other, TeckelChainTest::AddFriend
      end

      subject.finalize!

      expect {
        subject.class_eval do
          step :yet_other, TeckelChainTest::AddFriend
        end
      }.to raise_error(frozen_error)
    end

    it "disallows changing around hook" do
      subject.class_eval do
        around -> {}
      end

      chain2 = TeckelChainTest::Chain.dup.finalize!
      expect {
        chain2.class_eval do
          around -> {}
        end
      }.to raise_error(frozen_error)
    end

    it "runs" do
      subject.finalize!

      result = subject.call(name: "Bob", age: 23)
      expect(result.success).to include(user: kind_of(User), friend: kind_of(User))
    end

    it "accepts mocks" do
      subject.finalize!

      allow(subject).to receive(:call) { :mocked }
      expect(subject.call).to eq(:mocked)
    end
  end

  describe "#clone" do
    subject { TeckelChainTest::Chain.dup }
    let(:klone) { subject.clone }

    it "clones" do
      expect(klone.object_id).not_to be_eql(subject.object_id)
    end

    it "clones config" do
      orig_config = subject.instance_variable_get(:@config)
      klone_config = klone.instance_variable_get(:@config)
      expect(klone_config.object_id).not_to be_eql(orig_config.object_id)
    end

    it "clones steps" do
      orig_settings = subject.instance_variable_get(:@config).instance_variable_get(:@config)[:steps]
      klone_settings = klone.instance_variable_get(:@config).instance_variable_get(:@config)[:steps]

      expect(orig_settings).to be_a(Array)
      expect(klone_settings).to be_a(Array)
      expect(klone_settings.object_id).not_to be_eql(orig_settings.object_id)
    end
  end

  describe "frozen" do
    subject { TeckelChainTest::Chain.dup }

    it "also freezes the config" do
      expect { subject.freeze }.to change {
        [
          subject.frozen?,
          subject.instance_variable_get(:@config).frozen?
        ]
      }.from([false, false]).to([true, true])
    end

    it "prevents changes to steps" do
      subject.freeze
      expect {
        subject.class_eval do
          step :yet_other, TeckelChainTest::AddFriend
        end
      }.to raise_error(frozen_error)
    end

    it "prevents changes to config" do
      subject.freeze
      expect {
        subject.class_eval do
          default_settings!(a: {say: "Chain Default"})
        end
      }.to raise_error(frozen_error)
    end

    describe "#clone" do
      subject { TeckelChainTest::Chain.dup }

      it "clones the class" do
        subject.freeze
        klone = subject.clone

        expect(klone).to be_frozen
        expect(klone.object_id).not_to be_eql(subject.object_id)
      end

      it "cloned class uses the same, frozen config" do
        subject.freeze
        klone = subject.clone

        orig_config = subject.instance_variable_get(:@config)
        klone_config = klone.instance_variable_get(:@config)

        expect(klone_config).to be_frozen
        expect(klone_config.object_id).to be_eql(orig_config.object_id)
      end
    end
  end
end
