# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in teckel.gemspec
gemspec

group :development, :test do
  gem "irb", "~> 1.4.1" if RUBY_VERSION >= "2.6" # byexample needs a specific irb version
  gem "dry-struct", ">= 1.1.1", "< 2"
  gem "dry-monads", ">= 1.3", "< 2"
  gem "dry-validation", ">= 1.5.6", "< 2"
  gem "ostruct"
  gem "benchmark"
end

group :test do
  gem "simplecov", "~> 0.22.0", require: false if RUBY_VERSION >= "2.5"
  gem "simplecov-cobertura"
end
