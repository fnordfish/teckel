# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in teckel.gemspec
gemspec

group :development, :test do
  gem "irb", ">= 1.2.7", "< 2", platform: :mri if RUBY_VERSION >= '2.5'
  gem "dry-struct", ">= 1.1.1", "< 2"
  gem "dry-monads", ">= 1.3", "< 2"
  gem "dry-validation", ">= 1.5.6", "< 2"

  source 'https://oss:vGh00LMdwYktjajyXGfRsSOcynuQi92M@gem.mutant.dev' do
    gem 'mutant-license'
  end
end

group :test do
  gem "simplecov", "~> 0.20.0", require: false if RUBY_VERSION >= '2.5'
end
