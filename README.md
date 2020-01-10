# Teckel

Ruby service classes with enforced<sup name="footnote-1-source">[1](#footnote-1)</sup> input, output and error data structure definition.

[![Gem Version](https://img.shields.io/gem/v/teckel.svg)][gem]
[![Build Status](https://github.com/dry-rb/dry-configurable/workflows/ci/badge.svg)][ci]
[![Maintainability](https://api.codeclimate.com/v1/badges/b3939aaec6271a567a57/maintainability)](https://codeclimate.com/github/fnordfish/teckel/maintainability)
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

For a full overview please see the Api Docs:

* [Operations](https://fnordfish.github.io/teckel/doc/Teckel/Operation.html)
* [Operations with Result objects](https://fnordfish.github.io/teckel/doc/Teckel/Operation/Results.html)
* [Chains](https://fnordfish.github.io/teckel/doc/Teckel/Chain.html)

This example uses [Dry::Types](https://dry-rb.org/gems/dry-types/) to illustrate the flexibility. There's no dependency on dry-rb, choose what you like.

```ruby
class CreateUser
  include Teckel::Operation

  # DSL style declaration
  input Types::Hash.schema(name: Types::String, age: Types::Coercible::Integer)

  # Constant style declaration
  Output = Types.Instance(User)

  # Well, also Constant style, but using classic `class` notation
  class Error < Dry::Struct
    attribute :message, Types::String
    attribute :status_code, Types::Integer
    attribute :meta, Types::Hash.optional
  end

  def call(input)
    user = User.create(input)
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

user = CreateUser.call(name: "Bob", age: 23)
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
[ci]: https://github.com/fnordfish/teckel/actions?query=workflow%3ACI
[inch]: http://inch-ci.org/github/fnordfish/teckel
