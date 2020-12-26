# Input Data Validation

Usually, input definitions are quite simple and raise an error if the provided data does not match. 
How to return a meaningful error result when input data does not conform to specifications.

This example uses [dry-validation](https://dry-rb.org/gems/dry-validation), but you are free on how to validate your input data.

{% filter remove_code_promt %}
```ruby
>> require "dry/validation"

>> class User
..   def initialize(name:, age:)
..     @name, @age = name, age
..   end
..   attr_reader :name, :age
..
..   class << self
..     attr_accessor :has_db
..   end
..
..   def save
..     !!User.has_db
..   end
.. 
..   def errors
..     User.has_db ? nil : { database: ["not connected"] }
..   end
.. end

>> Dry::Validation.load_extensions(:predicates_as_macros)
.. class CreateUserContract < Dry::Validation::Contract
..   import_predicates_as_macros
..
..   schema do
..     required(:name).filled(:string)
..     required(:age).value(:integer)
..   end
..
..   rule(:age).validate(gteq?: 18)
.. end
.. 
.. class CreateUser
..   include Teckel::Operation
..   result!
.. 
..   input CreateUserContract.new
..
..   input_constructor(->(input){
..     result = self.class.input.call(input)
..     if result.success?
..       result.to_h
..     else
..       fail!(message: "Input data validation failed", errors: result.errors.to_h)
..     end
..   })
.. 
..   output Types.Instance(User)
..   error  Types::Hash.schema(
..     message: Types::String,
..     errors: Types::Hash.map(Types::Symbol, Types::Array.of(Types::String))
..   )
.. 
..   def call(input)
..     user = User.new(**input)
..     
..     if user.save
..       success! user
..     else
..       fail!(message: "Could not save User", errors: user.errors)
..     end
..   end
.. 
..   finalize!
.. end
```
{% endfilter %}


{% filter remove_code_promt %}
```ruby
>> User.has_db = true
>> CreateUser.call(name: "Bob", age: 23).success
=> #<User:<...> @name="Bob", @age=23>
```
{% endfilter %}

Error from response from our validation in `input_constructor`:

{% filter remove_code_promt %}
```ruby
>> CreateUser.call(name: "Bob", age: 10).failure
=> {:message=>"Input data validation failed", :errors=>{:age=>["must be greater than or equal to 18"]}}
```
{% endfilter %}

Error response from the our operation `call`:

{% filter remove_code_promt %}
```ruby
>> User.has_db = false
>> CreateUser.call(name: "Bob", age: 23).failure
=> {:message=>"Could not save User", :errors=>{:database=>["not connected"]}}
```
{% endfilter %}

Errors raised in `input_constructor` need to conform to the defined `error`:

```ruby
>> class IncorrectFailure
..   include Teckel::Operation
.. 
..   result!
.. 
..   input(->(input) { input }) # pass
..   input_constructor(->(_input) {
..     fail!("Input data validation failed")
..   })
.. 
..   output none
..   error  Types::Hash.schema(message: Types::String)
.. 
..   def call(_); end
..
..   finalize!
.. end

>> IncorrectFailure.call rescue $ERROR_INFO
=> #<Dry::Types::ConstraintError:<...> "Input data validation failed" violates constraints (type?(Hash, "Input data validation failed") failed)>
```
