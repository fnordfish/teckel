# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in teckel.gemspec
gemspec

group :development, :test do
  gem "dry-struct", ">= 1.1.1", "< 2"
end

group :test do
  # somehow codeclimate testreporter cannot cope with simplecov 0.18 (yet)
  # https://github.com/codeclimate/test-reporter/issues/413
  gem "simplecov", "< 0.18.0", require: false
end
