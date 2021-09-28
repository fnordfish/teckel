# Development Guidelines

- Keep it simple.
- Favor easy debug-ability over clever solutions.
- Aim to be a 0-dependency lib (at runtime)

## Roadmap

- Get those uncovered mutations down (add/refactor tests, and/or refactor code)
- Add helpers for testing frameworks rspec and minitest. Something along the lines of:
  `expect_teckel_opertaion(MyOperation, with: {some: :settings}).to be_called(some: :params).and_return(SomeReturnObject)`

## Testing

- Default specs: `bundle exec rake spec`
- Testing yard doc sample: `bundle exec rake docs:yard:doctest`
- Running mutation tests: `bundle exec mutant run -- 'Teckel*'`
  * Limit scopes like `bundle exec mutant run -- 'Teckel::Operation::Result*'`` 
  * https://github.com/mbj/mutant/blob/master/docs/mutant-rspec.md
  * https://github.com/mbj/mutant/blob/master/docs/incremental.md

## Building docs

* make sure to have python3 installed
* Install dependencies: `pip3 install -r _pages/requirements.txt`
* Test doc samples: `./bin/byexample`
* Build pages: `cd _pages && mkdocs build --strict`
