# Changes

## 0.4.0 (UNRELEASED)

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
- Add "settings"/dependency injection to Operation and Chains [GH-7]
  ```ruby
  MyOperation.with(logger: STDOUT).call(params)

  MyChain.with(some_step: { logger: STDOUT }).call(params)
  ```
- Add support for setting your own Result objects.
    - They should include and implement `Teckel::Result` which is needed by `Chain`.
    - `Chain::StepFailure` got replaced with `Chain::Result`.
    - the `Teckel::Operation::Results` module was removed. To let Operation use the default Result object, use the new helper `result!` instead.

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
