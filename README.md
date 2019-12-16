# Waldi

Ruby service classes with enforced<sup name="footnote-1-source">[1](#footnote-1)</sup> input, output and error data structure definition.

[![Gem Version](https://img.shields.io/gem/v/waldi.svg)][gem]
[![Build Status](https://github.com/dry-rb/dry-configurable/workflows/ci/badge.svg)][ci]
[![API Documentation Coverage](http://inch-ci.org/github/dry-rb/dry-configurable.svg)][inch]

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'waldi'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install waldi

## Motivation

Working with [Interactor](https://github.com/collectiveidea/interactor), [Trailblazer's Operation](http://trailblazer.to/gems/operation) and [Dry-rb's Transaction](https://dry-rb.org/gems/dry-transaction) and probably a hand full of inconsistent "service objects", I missed a system that:

1. provides and enforces well defined input, output and error structures
2. makes chaining multiple operation easy and reliable
3. is easy to debug

## Usage

This example uses [Dry::Types](https://dry-rb.org/gems/dry-types/) to illustrate the flexibility. There's no dependency on dry-rb, choose what you like.

```ruby
class CreateUser
  include Waldi::Operation
  
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
    if user.safe
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

result = CreateUser.call(name: "Bob", age: 23)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fnordfish/waldi.
Feature requests should provide a detailed explanation of the missing or changed behavior, if possible including some sample code.

## Footnotes

- <a name="footnote-1">1</a>: Obviously, it's still Ruby and you can cheat. Don’t! [↩](#footnote-1-source)

[gem]: https://rubygems.org/gems/waldi
[ci]: https://github.com/fnordfish/waldi/actions?query=workflow%3ACI
[inch]: http://inch-ci.org/github/fnordfish/waldi
