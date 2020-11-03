# Chain basics

Chains run multiple Operations ("steps") in order, returning the success value of the last step.  
When any step returns a failure, the chain is stopped and that failure is returned.

Operations used as steps need to return result objects (implementing `Teckel::Result`).

Chains always return a result object including the name of the step they origin from.  
This is especially useful to switch error handling for failure results.

## Example

Defining a simple Chain with three steps.

{% filter remove_code_promt %}
```ruby
>> class CreateUser
..   include ::Teckel::Operation
..
..   result!
..
..   input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer.optional)
..   output Types.Instance(User)
..   error  Types::Hash.schema(message: Types::String, errors: Types::Array.of(Types::Hash))
..
..   def call(input)
..     user = User.new(name: input[:name], age: input[:age])
..     if user.save
..       success!(user)
..     else
..       fail!(message: "Could not save User", errors: user.errors)
..     end
..   end
.. end

>> class LogUser
..   include ::Teckel::Operation
..
..   result!
..
..   input Types.Instance(User)
..   error none
..   output input
..
..   def call(usr)
..     Logger.new(File::NULL).info("User #{usr.name} created")
..     success!(usr) # we need to return the correct output type
..   end
.. end

>> class AddFriend
..   include ::Teckel::Operation
..
..   result!
..
..   settings Struct.new(:fail_befriend)
..
..   input Types.Instance(User)
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

>> class MyChain
..   include Teckel::Chain
..
..   step :create, CreateUser
..   step :log, LogUser
..   step :befriend, AddFriend
.. 
..   finalize!
.. end

>> result = MyChain.call(name: "Bob", age: 23)
>> result
=> #<Teckel::Chain::Result:<...>>

>> result.success[:user]
=> #<User:<...> @name="Bob", @age=23>
   
>> result.success[:friend]
=> #<User:<...> @name="A friend", @age=42>

>> failure_result = MyChain.with(befriend: :fail).call(name: "Bob", age: 23)
>> failure_result
=> #<Teckel::Chain::Result:<...>>

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

## Pattern matching

Hash style:

{% filter remove_code_promt %}
```ruby
>> result = case MyChain.call(name: "Bob", age: 23)
.. in { success: false, step: :befriend, value: value }
..   ["Failed", value]
.. in { success: true, value: value }
..   ["Success result", value]
.. end

>> result
=> ["Success result", {:user=>#<User:<...> @name="Bob", @age=23>, :friend=>#<User:<...> @name="A friend", @age=42>}]
```
{% endfilter %}

Array style:

{% filter remove_code_promt %}
```ruby
>> result = case MyChain.with(befriend: :fail).call(name: "Bob", age: 23)
.. in [false, :befriend, value]
..   ["Failed", value]
.. in [true, value]
..   ["Success result", value]
.. end

>> result
=> ["Failed", {:message=>"Did not find a friend."}]
```
{% endfilter %}
