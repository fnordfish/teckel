# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "teckel/version"

Gem::Specification.new do |spec|
  spec.name          = "teckel"
  spec.version       = Teckel::VERSION
  spec.authors       = ["Robert Schulze"]
  spec.email         = ["robert@dotless.de"]
  spec.licenses      = ['Apache-2.0']

  spec.summary       = 'Operations with enforced in/out/err data structures'
  spec.description   = 'Wrap your business logic into a common interface with enforced input, output and error data structures'
  spec.homepage      = "https://github.com/fnordfish/teckel"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z -- .yardopts LICENSE* CHANGELOG* README* lib/`.split("\x0")
  end
  spec.test_files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z -- spec/`.split("\x0")
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.metadata['changelog_uri']     = 'https://github.com/github.com/fnordfish/blob/master/CHANGELOG.md'
  spec.metadata['source_code_uri']   = 'https://github.com/github.com/fnordfish'
  spec.metadata['bug_tracker_uri']   = 'https://github.com/github.com/fnordfish/issues'
  spec.metadata['documentation_uri'] = "https://www.rubydoc.info/gems/teckel/#{Teckel::VERSION}"

  spec.required_ruby_version = ">= 2.4.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "yard-doctest"
end
