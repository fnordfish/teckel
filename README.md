# Teckel

Ruby service classes with enforced<sup name="footnote-1-source">[1](#footnote-1)</sup> input, output and error data structure definition.

[![Gem Version](https://img.shields.io/gem/v/teckel.svg)][gem]
[![Build Status](https://github.com/fnordfish/teckel/actions/workflows/specs.yml/badge.svg)][ci]
[![Maintainability](https://api.codeclimate.com/v1/badges/b3939aaec6271a567a57/maintainability)](https://codeclimate.com/github/fnordfish/teckel/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/b3939aaec6271a567a57/test_coverage)](https://codeclimate.com/github/fnordfish/teckel/test_coverage)
[![API Documentation Coverage](https://inch-ci.org/github/fnordfish/teckel.svg?branch=master)][inch]

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'teckel'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install teckel

## Motivation

Working with [Interactor](https://github.com/collectiveidea/interactor), [Trailblazer's Operation](http://trailblazer.to/gems/operation) and [Dry-rb's Transaction](https://dry-rb.org/gems/dry-transaction) and probably a hand full of inconsistent "service objects", I missed a system that:

1. provides and enforces well defined input, output and error structures
2. makes chaining multiple operation easy and reliable
3. is easy to debug

## Usage

For a full overview please see the Docs:

* [Operations](https://fnordfish.github.io/teckel/operations/basics/)
* [Result Objects](https://fnordfish.github.io/teckel/operations/result_objects/)
* [Chains](https://fnordfish.github.io/teckel/chains/basics/)


```ruby
class CreateUser
  include Teckel::Operation

  # DSL style declaration
  input Struct.new(:name, :age, keyword_init: true)

  # Constant style declaration
  Output = ::User

  # Well, also Constant style, but using classic `class` notation
  class Error
    def initialize(message:, status_code:, meta:)
      @message, @status_code, @meta = message, status_code, meta
    end
    attr_reader :message, :status_code, :meta
  end
  error_constructor :new

  def call(input)
    user = User.new(name: input.name, age: input.age)
    if user.save
      success!(user)
    else
      fail!(
        message: "Could not create User",
        status_code: 400,
        meta: { validation: user.errors }
      )
    end
  end
end

CreateUser.call(name: "Bob", age: 23) #=> #<User @age=23, @name="Bob">

CreateUser.call(name: "Bob", age: 5)  #=> #<CreateUser::Error @message="Could not create User", @meta={:validation=>[{:age=>"underage"}]}, @status_code=400>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fnordfish/teckel.
Feature requests should provide a detailed explanation of the missing or changed behavior, if possible including some sample code.

Please also see [DEVELOPMENT.md](DEVELOPMENT.md) for planned features and general guidelines.

## Footnotes

- <a name="footnote-1">1</a>: Obviously, it's still Ruby and you can cheat. Don’t! [↩](#footnote-1-source)

[gem]: https://rubygems.org/gems/teckel
[ci]: https://github.com/fnordfish/teckel/actions/workflows/specs.yml
[inch]: http://inch-ci.org/github/fnordfish/teckel
