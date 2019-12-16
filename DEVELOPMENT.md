# Development Guidelines

- Keep is simple.
- Favor easy debug-ability over clever solutions.
- Aim to be a 0-dependency lib (at runtime)

## Roadmap

- Add "Settings" for Operations and Chains

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
- Add support for around hooks in Chains (for db transactions etc.)
- Add a dry-monads mixin to wrap Operations and Chains result/error into a Result Monad
- ...

