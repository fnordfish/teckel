# Development Guidelines

- Keep it simple.
- Favor easy debug-ability over clever solutions.
- Aim to be a 0-dependency lib (at runtime)

## Roadmap

- Add "Settings"/Dependency injection for Operations and Chains

    ```
    MyOp.with(foo: "bar").call("input")

    class MyOp
      settings Types::Hash.schema(foo: Types::String)

      def call(input)
        input == "input"
        settings.foo == "bar"
      end
    end

    MyCain.with(:step1) { { foo: "bar" } }.with(:stepX) { { another: :setting} }.call(params)
    ```
- Add a dry-monads mixin to wrap Operations and Chains result/error into a Result Monad (for example see https://dry-rb.org/gems/dry-types/master/extensions/monads/)
    ```
    MyOp.call("input").to_monad do
    end
    ```
  This is kind of available using `.result`, which allows wrapping the operations output into anything.
- ...

