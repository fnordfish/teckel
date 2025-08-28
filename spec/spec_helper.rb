# frozen_string_literal: true

require "bundler/setup"

if ENV["COVERAGE"] == "true"
  require "simplecov"
  require "simplecov_json_formatter"

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ])

  SimpleCov.start do
    add_filter %r{^/spec/}
  end
end

require "teckel"
require "teckel/chain"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.formatter = (config.files_to_run.size > 1) ? :progress : :documentation

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
