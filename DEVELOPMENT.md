# Development Guidelines

- Keep it simple.
- Favor easy debug-ability over clever solutions.
- Aim to be a 0-dependency lib (at runtime)

## Roadmap

- Add Mutation testing with [mutant](https://github.com/mbj/mutant)
  ```
  source 'https://oss:vGh00LMdwYktjajyXGfRsSOcynuQi92M@gem.mutant.dev' do 
    gem 'mutant-license' 
  end 
  ```

- 

## Building docs

* make sure to have python3 installed
* Install dependencies: `pip3 install -r _pages/requirements.txt`
* Test doc samples: `./bin/byexample`
* Build pages: `cd _pages && mkdocs build --strict`
