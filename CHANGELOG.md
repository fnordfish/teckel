# Changes

- Breaking: `Teckel::Chain` will not be required by default. require manually if needed `require "teckel/chain"` [GH-24]
- Breaking: Internally, `Teckel::Operation::Runner` instead of `:success` and `:failure` now only uses `:halt` as it's throw-catch symbol. [GH-26]
- Add: Using the default `Teckel::Operation::Runner`, `input_constructor` and `result_constructor` will be executed
  within the context of the operation instance. This allows for `input_constructor` to call `fail!` and `success!` 
  without ever `call`ing the operation. [GH-26]


## 0.6.0

- Breaking: Operations return values will be ignored. [GH-21]
  * You'll need to use `success!` or `failure!` 
  * `success!` and `failure!` are now implemented on the `Runner`, which makes it easier to change their behavior (including the one above).

## 0.5.0

- Fix: calling chain with settings and no input [GH-14]
- Add: Default settings for Operation and Chains [GH-17], [GH-18]
  ```ruby
  class MyOperation
    include Teckel::Operation

    settings Struct.new(:logger) 

    # If your settings class can cope with no input and you want to make sure
    # `settings` gets initialized and set.
    # settings will be #<struct logger=nil>
    default_settings!

    # settings will be #<struct logger=MyGlobalLogger>
    default_settings!(MyGlobalLogger)

    # settings will be #<struct logger=#<Logger:<...>>
    default_settings! -> { settings.new(Logger.new("/tmp/my.log")) }
  end

  class Chain
    include Teckel::Chain

    # set or overwrite operation settings
    default_settings!(a: MyOtherLogger)

    step :a, MyOperation
  end
  ```

Internal:
- Move operation and chain config dsl methods into own module [GH-15]
- Code simplifications [GH-16]

## 0.4.0

- Moving verbose examples from API docs into github pages
- `#finalize!` no longer freezes the entire Operation or Chain class, only it's settings. [GH-13]
- Add simple support for using Base classes. [GH-10]
  Removes global configuration `Teckel::Config.default_constructor`
  ```ruby
  class ApplicationOperation
    include Teckel::Operation
    # you won't be able to overwrite any configuration in child classes,
    # so take care which you want to declare
    result!
    settings Struct.new(:logger)
    input_constructor :new
    error Struct.new(:status, :messages)

    def log(message)
      return unless settings&.logger
      logger << message
    end
    # you cannot call `finalize!` on partially declared Operations
  end
  ```
- Add support for setting your own Result objects. [GH-9]
  - They should include and implement `Teckel::Result` which is needed by `Chain`.
  - `Chain::StepFailure` got replaced with `Chain::Result`.
  - the `Teckel::Operation::Results` module was removed. To let Operation use the default Result object, use the new helper `result!` instead.
- Add "settings"/dependency injection to Operation and Chains. [GH-7]
  ```ruby
  MyOperation.with(logger: STDOUT).call(params)

  MyChain.with(some_step: { logger: STDOUT }).call(params)
  ```
- [GH-5] Add support for ruby 2.7 pattern matching on Operation and Chain results. Both, array and hash notations are supported:
  ```ruby
  case MyOperation.call(params)
  in [false, value]
    # handle failure
  in [true, value]
    # handle success
  end

  case MyChain.call(params)
  in { success: false, step: :foo, value: value } 
    # handle foo failure
  in [success: false, step: :bar, value: value }
    # handle bar failure
  in { success: true, value: value }
    # handle success
  end
  ```
- Fix setting a config twice to raise an error

## 0.3.0

- `finalize!`'ing a Chain will also finalize all it's Operations
- Changed attribute naming of `StepFailure`:
    + `.operation` will now give the operation class of the step - was `.step` before
    + `.step` will now give the name of the step (which Operation failed) - was `.step_name` before

## 0.2.0

- Around Hooks for Chains
- `finalize!` 
  - freezing Chains and Operations, to prevent further changes
  - Operations check their config and raise if any is missing

## 0.1.0

- Initial release
