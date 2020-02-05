# Inject settings

Your `call` method should only get data to work on. Use settings for "how" or "with what" to do it.

Settings (just as input, output and error) are defined using a contract class and made available via the `#settings` instance method only when set.

{% filter remove_code_promt %}
```ruby
>> class MyOperation
..   include ::Teckel::Operation
.. 
..   settings Struct.new(:logger)
..
..   input none
..   output none
..   error none
..
..   def call(_input)
..     puts "no settings" if settings.nil?
..     settings.logger.puts "called" if settings&.logger
..     nil
..   end
.. end
```
{% endfilter %}

With no settings:

{% filter remove_code_promt %}
```ruby
>> MyOperation.call(nil)
no settings
=> nil
```
{% endfilter %}

With Logger

{% filter remove_code_promt %}
```ruby
>> require 'stringio'

>> my_logger = StringIO.new
>> MyOperation.with(my_logger).call()
>> my_logger.string
=> "called\n"
```
{% endfilter %}

## As constant

{% filter remove_code_promt %}
```ruby
>> class OtherOperation
..   include Teckel::Operation
..   class Settings
..     def initialize(foo:, bar:)
..       @foo, @bar = foo, bar
..     end
..     attr_reader :foo, :bar
..   end
..   # MyOperation.with("foo", "bar") # -> Settings.new("foo", "bar")
..   settings_constructor :new
.. end
```
{% endfilter %}
