# Development Guidelines

- Keep it simple.
- Favor easy debug-ability over clever solutions.
- Aim to be a 0-dependency lib (at runtime)

## Roadmap

- Add mutations tests to CI

## Testing

- Default specs: `bundle exec rake spec`
- Testing yard doc sample: `bundle exec rake docs:yard:doctest`
- Running mutation tests: `bundle exec mutant run -- 'Teckel::Operation*'`
  * https://github.com/mbj/mutant/blob/master/docs/mutant-rspec.md
  * https://github.com/mbj/mutant/blob/master/docs/incremental.md

>>>>>>> 9041466 (Add mutant)

## Building docs

* make sure to have python3 installed
* Install dependencies: `pip3 install -r _pages/requirements.txt`
* Test doc samples: `./bin/byexample`
* Build pages: `cd _pages && mkdocs build --strict`
