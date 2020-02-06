# Introduction

![][Teckel Logo]

Teckel provides a common interface for wrapping your ruby business logic into,  
with enforced input, output and error data structures.

The two main components are [Operations](operations/basics) and [Chains](chains/basics).

## Motivation

Working with [Interactor](https://github.com/collectiveidea/interactor), [Trailblazer's Operation](http://trailblazer.to/gems/operation) and [Dry-rb's Transaction](https://dry-rb.org/gems/dry-transaction) and probably a hand full of inconsistent "service objects", I missed a system that:

1. provides and enforces well defined input, output and error structures
2. makes chaining multiple operation easy and reliable
3. is easy to debug

## About Code Samples

Code samples are tested using [byexamples](https://byexamples.github.io).

They all use a common base setup to have some fake objects to work with:

```ruby
{% include 'docs_base.rb' without context %}
```


[Teckel Logo]: images/logo_lg.png
