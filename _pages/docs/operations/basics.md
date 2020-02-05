# Operation basics

## Using in-line constants as contracts

{% filter remove_code_promt %}
```ruby
>> class CreateUserInline
..   include Teckel::Operation
..
..   class Input
..     def initialize(name:, age:)
..       @name, @age = name, age
..     end
..     attr_reader :name, :age
..   end
..
..   input_constructor ->(data) { input.new(**data) }
..
..   Output = ::User
..
..   class Error
..     def initialize(message, errors)
..       @message, @errors = message, errors
..     end
..     attr_reader :message, :errors
..   end
..
..   error_constructor :new
..
..   def call(input)
..     user = ::User.new(name: input.name, age: input.age)
..     if user.save
..       user
..     else
..       fail!("Could not save User", user.errors)
..     end
..   end
.. end
```
{% endfilter %}

A Successful call:

{% filter remove_code_promt %}
```ruby
>> CreateUserInline.call(name: "Bob", age: 23)
=> #<User:<...> @name="Bob", @age=23>
```
{% endfilter %}

A failure call:

{% filter remove_code_promt %}
```ruby
>> CreateUserInline.call(name: "Bob", age: 10)
=> #<CreateUserInline::Error:<...> @message="Could not save User", @errors=[{:age=>"underage"}]>
```
{% endfilter %}

Calling with unsuspected input:

{% filter remove_code_promt %}
```ruby
>> CreateUserInline.call(unwanted: "input") rescue $ERROR_INFO
=> #<ArgumentError: missing keywords: :name, :age>

>> CreateUserInline.call(unwanted: "input", name: "a", age: 10) rescue $ERROR_INFO
=> #<ArgumentError: unknown keyword: :unwanted>
```
{% endfilter %}

## Using Dry::Types as contracts

Here is a simple Operation using Dry::Types for it's input, output and error contracts:

{% filter remove_code_promt %}
```ruby
>> class CreateUserDry
..   include Teckel::Operation
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

A Successful call:

{% filter remove_code_promt %}
```ruby
>> CreateUserDry.call(name: "Bob", age: 23)
=> #<User:<...> @name="Bob", @age=23>
```
{% endfilter %}

A failure call:

{% filter remove_code_promt %}
```ruby
>> CreateUserDry.call(name: "Bob", age: 10)
=> {:message=>"Could not save User", :errors=>[{:age=>"underage"}]}
```
{% endfilter %}

Build your contracts in a way that let you know:

{% filter remove_code_promt %}
```ruby
>> CreateUserDry.call(unwanted: "input") rescue $ERROR_INFO
=> #<Dry::Types::MissingKeyError: :name is missing in Hash input>
```
{% endfilter %}

If your contracts support Feed an instance of the input class directly to call:

{% filter remove_code_promt %}
```ruby
>> CreateUserDry.call(CreateUserDry.input[name: "Bob", age: 23])
=> #<User:<...> @name="Bob", @age=23>
```
{% endfilter %}

## Expecting `none`

{% filter remove_code_promt %}
```ruby
>> class NoOp
..   include Teckel::Operation
..   
..   input none
..   output none
..   error none
..   
..   # injecting values to fake behavior
..   settings Struct.new(:out, :err, :ret, keyword_init: true)
..   
..   def call(_input) # you'll still need to take that argument
..     if settings
..       fail!(nil)             if settings.err == :nil
..       success!(nil)          if settings.out == :nil
..       fail!(settings.err)    if settings.err
..       success!(settings.out) if settings.out
..       
..       settings.ret
..     end
..     # make sure no value is returned here.
..   end
.. end
```
{% endfilter %}

Expects to be called with nothing or `nil`, calling with any value will raise an error:

{% filter remove_code_promt %}
```ruby
>> NoOp.call
=> nil

>> NoOp.call(nil)
=> nil

>> NoOp.call("test") rescue $ERROR_INFO
=> #<ArgumentError: None called with arguments>
```
{% endfilter %}

Expects no success value, that include any return value:

{% filter remove_code_promt %}
```ruby
>> NoOp.with(out: nil).call
=> nil

>> NoOp.with(out: :nil).call
=> nil

>> NoOp.with(out: "test").call rescue $ERROR_INFO
=> #<ArgumentError: None called with arguments>

>> NoOp.with(ret: "test").call rescue $ERROR_INFO
=> #<ArgumentError: None called with arguments>
```
{% endfilter %}

Expects no failure value:

{% filter remove_code_promt %}
```ruby
>> NoOp.with(err: nil).call
=> nil

>> NoOp.with(err: :nil).call
=> nil

>> NoOp.with(err: "test").call rescue $ERROR_INFO
=> #<ArgumentError: None called with arguments>
```
{% endfilter %}

## Pattern matching

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
```
{% endfilter %}

Hash style:

{% filter remove_code_promt %}
```ruby
>> result = case CreateUser.call(name: "Bob", age: 23)
.. in { success: false, value: value }
..   ["Failed", value]
.. in { success: true, value: value }
..   ["Success result", value]
.. end

>> result
=> ["Success result", #<User:<...> @name="Bob", @age=23>]
```
{% endfilter %}

Array style:

{% filter remove_code_promt %}
```ruby
>> result = case CreateUser.call(name: "Bob", age: 10)
.. in [false, value]
..   ["Failed", value]
.. in [true, value]
..   ["Success result", value]
.. end

>> result
=> ["Failed", {:message=>"Could not save User", :errors=>[{:age=>"underage"}]}]
```
{% endfilter %}
