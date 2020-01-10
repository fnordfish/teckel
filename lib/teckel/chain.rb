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
  #
  # @example DB transaction around hook
  #   class CreateUser
  #     include ::Teckel::Operation::Results
  #
  #     input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer.optional)
  #     output Types.Instance(User)
  #     error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))
  #
  #     def call(input)
  #       user = User.new(name: input[:name], age: input[:age])
  #       if user.safe
  #         success!(user)
  #       else
  #         fail!(message: "Could not safe User", errors: user.errors)
  #       end
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
  #   LOG = []
  #
  #   class MyChain
  #     include Teckel::Chain
  #
  #     around ->(chain, input) {
  #       result = nil
  #       begin
  #         LOG << :before
  #
  #         FakeDB.transaction do
  #           result = chain.call(input)
  #           raise FakeDB::Rollback if result.failure?
  #         end
  #
  #         LOG << :after
  #         result
  #       rescue FakeDB::Rollback
  #         LOG << :rollback
  #         result
  #       end
  #     }
  #
  #     step :create, CreateUser
  #     step :befriend, AddFriend
  #   end
  #
  #   AddFriend.fail_befriend = true
  #   failure_result = MyChain.call(name: "Bob", age: 23)
  #   failure_result.is_a?(Teckel::Chain::StepFailure) #=> true
  #
  #   # triggered DB rollback
  #   LOG                                              #=> [:before, :rollback]
  #
  #   # additional step information
  #   failure_result.step_name                         #=> :befriend
  #   failure_result.step                              #=> AddFriend
  #
  #   # otherwise behaves just like a normal +Result+
  #   failure_result.failure?                          #=> true
  #   failure_result.failure                           #=> {message: "Did not find a friend."}
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

    # The default implementation for executing a {Chain}
    #
    # @!visibility protected
    class Runner
      def initialize(steps)
        @steps = steps
      end
      attr_reader :steps

      # Run steps
      #
      # @param input Any form of input the first steps +input+ class can handle
      #
      # @return [Teckel::Result,Teckel::Chain::StepFailure] The result object wrapping
      #   either the success or failure value. Note that the {StepFailure} behaves
      #   just like a {Teckel::Result} with added information about which step failed.
      def call(input)
        last_result = input
        failed = nil
        steps.each do |(name, step)|
          last_result = step.call(last_result)
          if last_result.failure?
            failed = StepFailure.new(step, name, last_result)
            break
          end
        end

        failed || last_result
      end
    end

    module ClassMethods
      # The expected input for this chain
      # @return [Class] The {Teckel::Operation.input} of the first step
      def input
        @steps.first&.last&.input
      end

      # The expected output for this chain
      # @return [Class] The {Teckel::Operation.output} of the last step
      def output
        @steps.last&.last&.output
      end

      # List of all possible errors
      # @return [<Class>] List of all steps {Teckel::Operation.error}s
      def errors
        @steps.each_with_object([]) do |e, m|
          err = e.last&.error
          m << err if err
        end
      end

      # Declare a {Operation} as a named step
      #
      # @param name [String,Symbol] The name of the operation.
      #   This name is used in an error case to let you know which step failed.
      # @param operation [Operation::Results] The operation to call.
      #   Must return a {Teckel::Result} object.
      def step(name, operation)
        @steps << [name, operation]
      end

      # Set or get the optional around hook.
      # A Hook might be given as a block or anything callable. The execution of
      # the chain is yielded to this hook. The first argument being the callable
      # chain ({Runner}) and the second argument the +input+ data. The hook also
      # needs to return the result.
      #
      # @param callable [Proc,{#call}] The hook to pass chain execution control to. (nil)
      #
      # @return [Proc,{#call}] The configured hook
      #
      # @example Around hook with block
      #   OUTPUTS = []
      #
      #   class Echo
      #     include ::Teckel::Operation::Results
      #
      #     input Hash
      #     output input
      #
      #     def call(hsh)
      #       hsh
      #     end
      #   end
      #
      #   class MyChain
      #     include Teckel::Chain
      #
      #     around do |chain, input|
      #       OUTPUTS << "before start"
      #       result = chain.call(input)
      #       OUTPUTS << "after start"
      #       result
      #     end
      #
      #     step :noop, Echo
      #   end
      #
      #   result = MyChain.call(some: 'test')
      #   OUTPUTS #=> ["before start", "after start"]
      #   result.success #=> { some: "test" }
      def around(callable = nil, &block)
        @around = callable if callable
        @around ||= block if block
        @around
      end

      # @!attribute [r] runner()
      # @return [Class] The Runner class
      # @!visibility protected

      # Overwrite the default runner
      # @param klass [Class] A class like the {Runner}
      # @!visibility protected
      def runner(klass = nil)
        @runner = klass if klass
        @runner
      end

      # The primary interface to call the chain with the given input.
      #
      # @param input Any form of input the first steps +input+ class can handle
      #
      # @return [Teckel::Result,Teckel::Chain::StepFailure] The result object wrapping
      #   either the success or failure value. Note that the {StepFailure} behaves
      #   just like a {Teckel::Result} with added information about which step failed.
      def call(input)
        runner = self.runner.new(@steps.dup)
        if around
          around.call(runner, input)
        else
          runner.call(input)
        end
      end
    end

    def self.included(receiver)
      receiver.extend ClassMethods

      receiver.class_eval do
        @steps = []
        @around = nil
        @runner = Runner
      end
    end
  end
end
