# Around hook

Chains might use a around hook eg. for wrapping the entire execution in a database transaction.
There hooks gets total control over the execution, so it needs to take care of calling the chain and returning it's result.

{% filter remove_code_promt %}
```ruby
>> class CreateUser
..   include ::Teckel::Operation
..
..   result!
..   input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer.optional)
..   output Types.Instance(User)
..   error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))
..
..   def call(input)
..     user = User.new(name: input[:name], age: input[:age])
..     if user.save
..       success!(user)
..     else
..       fail!(message: "Could not safe User", errors: user.errors)
..     end
..   end
.. end

>> class AddFriend
..   include ::Teckel::Operation
..
..   result!
..   settings Struct.new(:fail_befriend)
..   input  Types.Instance(User)
..   output Types::Hash.schema(user: Types.Instance(User), friend: Types.Instance(User))
..   error  Types::Hash.schema(message: Types::String)
..
..   def call(user)
..     if settings&.fail_befriend == :fail
..       fail!(message: "Did not find a friend.")
..     else
..       success!(user: user, friend: User.new(name: "A friend", age: 42))
..     end
..   end
.. end

>> LOG = []

>> class MyChain
..   include Teckel::Chain
..
..   around ->(chain, input) {
..     result = nil
..     begin
..       LOG << :before
..       FakeDB.transaction do
..         # The hook needs to call the chain:    
..         result = chain.call(input)
..
..         raise FakeDB::Rollback if result.failure?
..       end
..       LOG << :after
..
..       result # ... and return the success result
..     rescue FakeDB::Rollback
..       LOG << :rollback
.. 
..       result # ... and return the failure result
..     end
..   }
..
..   step :create, CreateUser
..   step :befriend, AddFriend
.. end

>> failure_result = MyChain.with(befriend: :fail).call(name: "Bob", age: 23)
>> failure_result
=> #<Teckel::Chain::Result:<...>>

# triggered DB rollback
>> LOG
=> [:before, :rollback]

# additional step information
>> failure_result.step
=> :befriend

# behaves just like a normal +Result+
>> failure_result.failure?
=> true

>> failure_result.failure
=> {:message=>"Did not find a friend."}
```
{% endfilter %}
