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

## Default Settings

Initialize Setting by default.  
This avoids `nil` settings, but forces you to either make your `Settings` class  
accept no arguments for initialization, or provide acceptable defaults.

Note that, default settings will not get merged with call time setting.
Default settings will be ignored when calling like this: `MyOperation.with(call_time_settings).call`.

{% filter remove_code_promt %}
```ruby
>> class BaseOperation
..   include Teckel::Operation
..
..   class Settings
..     def initialize(*values)
..       @values = values
..     end
..     attr_reader :values
..   end
..
..   settings_constructor :new
..
..   input  none
..   output Types::Array
..   error  none
..
..   def call(_)
..     success!(settings.values)
..   end
.. end
```
{% endfilter %}

### Empty defaults

{% filter remove_code_promt %}
```ruby
>> class EmptyDefaults < BaseOperation
..   default_settings! # Settings.new
.. end
```
{% endfilter %}

With no settings:

{% filter remove_code_promt %}
```ruby
>> EmptyDefaults.call
=> []
```
{% endfilter %}

With injected settings:

{% filter remove_code_promt %}
```ruby
>> EmptyDefaults.with(:injected).call
=> [:injected]
```
{% endfilter %}

### Static defaults

{% filter remove_code_promt %}
```ruby
>> class StaticDefaults < BaseOperation
..   default_settings!(:foo, :bar) # Settings.new(:foo, :bar)
.. end
```
{% endfilter %}

With no settings:

{% filter remove_code_promt %}
```ruby
>> StaticDefaults.call
=> [:foo, :bar]
```
{% endfilter %}

With injected settings:

{% filter remove_code_promt %}
```ruby
>> StaticDefaults.with(:injected).call
=> [:injected]
```
{% endfilter %}


### Call time defaults

{% filter remove_code_promt %}
```ruby
>> class CallTimeDefaults < BaseOperation
..   default_settings! -> { settings_constructor.call(Time.now) } # Settings.new(Time.now)
.. end
```
{% endfilter %}

With no settings:

{% filter remove_code_promt %}
```ruby
>> a = CallTimeDefaults.call.first
>> b = CallTimeDefaults.call.first
>> a.class
=> Time
>> b.class
=> Time
>> a < b
=> true
```
{% endfilter %}

With injected settings:

{% filter remove_code_promt %}
```ruby
>> CallTimeDefaults.with(:injected).call
=> [:injected]
```
{% endfilter %}
