# Development Guidelines

- Keep it simple.
- Favor easy debug-ability over clever solutions.
- Aim to be a 0-dependency lib (at runtime)

## Roadmap

- Refactor tests/code with Mutation testing on branch [`feature/mutant`](https://github.com/fnordfish/teckel/tree/feature/mutant)

## Building docs

* make sure to have python3 installed
* Install dependencies: `pip3 install -r _pages/requirements.txt`
* Test doc samples: `./bin/byexample`
* Build pages: `cd _pages && mkdocs build --strict`
