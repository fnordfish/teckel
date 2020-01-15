# Changes

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
