# Result objects


## Build-in

{% filter remove_code_promt %}
```ruby
>> class CreateUser
..   include Teckel::Operation
..
..   # Shortcut for
..   # result Teckel::Operation::Result
..   result!
..
..   input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)
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
```
{% endfilter %}

A success call:

{% filter remove_code_promt %}
```ruby
>> result = CreateUser.call(name: "Bob", age: 23)
>> result
=> #<Teckel::Operation::Result:<...>>

>> result.successful?
=> true

>> result.failure?
=> false

>> result.success
=> #<User:<...> @age=23, @name="Bob">
```
{% endfilter %}

A failure call:

{% filter remove_code_promt %}
```ruby
>> result = CreateUser.call(name: "Bob", age: 10)
>> result
=> #<Teckel::Operation::Result:<...>>

>> result.successful?
=> false

>> result.failure?
=> true

>> result.failure
=> {errors: [{age: "underage"}], message: "Could not save User"}

>> result.success do |value|
..   # do something with the error value
..   puts value[:message]
..   # return something useful
..   value[:errors]
.. end
  Could not save User
=> [{age: "underage"}]
```
{% endfilter %}

## Custom

You can use your own result object.
If you plan using your operation in a `Chain`, the should implement the interface defined in `Teckel::Result`.

{% filter remove_code_promt %}
```ruby
>> require 'time'

>> class MyResult
..   include Teckel::Result
..   def initialize(value, success, opts = {})
..     @value, @success, @opts = value, (!!success).freeze, opts
..   end
..
..   # implementing Teckel::Result
..   attr_reader :value
..
..   # implementing Teckel::Result
..   def successful?
..     @success
..   end
..
..   def at
..     @opts[:at]
..   end
.. end

>> class CreateUserOtherResult
..   include Teckel::Operation
..
..   result MyResult
..   result_constructor ->(value, success) { MyResult.new(value, success, at: Time.now) }
..
..   input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)
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
..   finalize!
.. end

>> result = CreateUserOtherResult.call(name: "Bob", age: 23)
>> result
=> #<MyResult:<...>
  @opts={at: <time>}, 
  @success=true,
  @value=#<User:<...>>

>> result.at
=> <time>

>> result.successful?
=> true

>> result.failure?
=> false

>> result.value
=> #<User:<...> @age=23, @name="Bob">
```
{% endfilter %}

## Dry-Monads

{% filter remove_code_promt %}
```ruby
>> require 'dry/monads'

>> # we need some glue code to make them work with Chains
>> class DryResult
..   include Teckel::Result
..   include Dry::Monads[:result]
..   
..   def initialize(value, success)
..     @value, @success = value, (!!success).freeze
..   end
..
..   # implementing Teckel::Result
..   attr_reader :value
..
..   # implementing Teckel::Result
..   def successful?
..     @success
..   end
..
..   def to_monad
..     @success ? Success(value) : Failure(value)
..   end
.. end

>> class CreateUserDry
..   include Teckel::Operation
..
..   result DryResult
..   result_constructor :new
..
..   input  Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)
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
..   finalize!
.. end

>> result = CreateUserDry.call(name: "Bob", age: 23)
>> result.to_monad
=> Success(#<User:<...> @age=23, @name="Bob">)
```
{% endfilter %}
