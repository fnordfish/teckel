# frozen_string_literal: true

require 'forwardable'

module Teckel
  # Railway style execution of multiple Operations.
  #
  # - Runs multiple Operations (steps) in order.
  # - The output of an earlier step is passed as input to the next step.
  # - Any failure will stop the execution chain (none of the later steps is called).
  # - All Operations (steps) must behave like
  #   {Teckel::Operation::Results Teckel::Operation::Results} and return a result
  #   object like {Teckel::Result}
  # - A failure response is wrapped into a {Teckel::Chain::StepFailure} giving
  #   additional information about which step failed
  #
  # @see Teckel::Operation::Results
  #
  # @example Defining a simple Chain with three steps
  #   class CreateUser
  #     include ::Teckel::Operation::Results
  #
  #     input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer.optional)
  #     output Types.Instance(User)
  #     error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))
  #
  #     def call(input)
  #       user = User.new(name: input[:name], age: input[:age])
  #       if user.save
  #         success!(user)
  #       else
  #         fail!(message: "Could not save User", errors: user.errors)
  #       end
  #     end
  #   end
  #
  #   class LogUser
  #     include ::Teckel::Operation::Results
  #
  #     input Types.Instance(User)
  #     output input
  #
  #     def call(usr)
  #       Logger.new(File::NULL).info("User #{usr.name} created")
  #       usr # we need to return the correct output type
  #     end
  #   end
  #
  #   class AddFriend
  #     class << self
  #       # Don't actually do this! It's not safe and for generating the failure sample only.
  #       attr_accessor :fail_befriend
  #     end
  #
  #     include ::Teckel::Operation::Results
  #
  #     input Types.Instance(User)
  #     output Types::Hash.schema(user: Types.Instance(User), friend: Types.Instance(User))
  #     error  Types::Hash.schema(message: Types::String)
  #
  #     def call(user)
  #       if self.class.fail_befriend
  #         fail!(message: "Did not find a friend.")
  #       else
  #         { user: user, friend: User.new(name: "A friend", age: 42) }
  #       end
  #     end
  #   end
  #
  #   class MyChain
  #     include Teckel::Chain
  #
  #     step :create, CreateUser
  #     step :log, LogUser
  #     step :befriend, AddFriend
  #   end
  #
  #   result = MyChain.call(name: "Bob", age: 23)
  #   result.is_a?(Teckel::Result)          #=> true
  #   result.success[:user].is_a?(User)    #=> true
  #   result.success[:friend].is_a?(User)  #=> true
  #
  #   AddFriend.fail_befriend = true
  #   failure_result = MyChain.call(name: "Bob", age: 23)
  #   failure_result.is_a?(Teckel::Chain::StepFailure) #=> true
  #
  #   # additional step information
  #   failure_result.step_name                        #=> :befriend
  #   failure_result.step                             #=> AddFriend
  #
  #   # otherwise behaves just like a normal +Result+
  #   failure_result.failure?                         #=> true
  #   failure_result.failure                          #=> {message: "Did not find a friend."}
  module Chain
    # Like {Teckel::Result Teckel::Result} but for failing Chains
    #
    # When a Chain fails, it stores the failed +Operation+ and it's name.
    class StepFailure
      extend Forwardable

      def initialize(step, step_name, result)
        @step, @step_name, @result = step, step_name, result
      end

      # @!attribute step [R]
      # @return [Teckel::Operation] the failed Operation
      attr_reader :step

      # @!attribute step_name [R]
      # @return [String] the step name of the failed Operation
      attr_reader :step_name

      # @!attribute result [R]
      # @return [Teckel::Result] the failure Result
      attr_reader :result

      # @!method value
      #   Delegates to +result.value+
      #   @see Teckel::Result#value
      # @!method successful?
      #   Delegates to +result.successful?+
      #   @see Teckel::Result#successful?
      # @!method success
      #   Delegates to +result.success+
      #   @see Teckel::Result#success
      # @!method failure?
      #   Delegates to +result.failure?+
      #   @see Teckel::Result#failure?
      # @!method failure
      #   Delegates to +result.failure+
      #   @see Teckel::Result#failure
      def_delegators :@result, :value, :successful?, :success, :failure?, :failure
    end

    module ClassMethods
      def input
        @steps.first&.last&.input
      end

      def output
        @steps.last&.last&.output
      end

      def errors
        @steps.each_with_object([]) do |e, m|
          err = e.last&.error
          m << err if err
        end
      end

      def call(input)
        new.call!(@steps, input)
      end

      def step(name, operation)
        @steps << [name, operation]
      end
    end

    module InstanceMethods
      def call!(steps, input)
        result = input
        failed = nil
        steps.each do |(name, step)|
          result = step.call(result)
          if result.failure?
            failed = StepFailure.new(step, name, result)
            break
          end
        end

        failed || result
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods

      receiver.class_eval do
        @steps = []
      end
    end
  end
end
