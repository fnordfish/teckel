# frozen_string_literal: true

require_relative "support/dry_base"
require_relative "support/fake_db"
require_relative "support/fake_models"

lib = File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "teckel"
require "teckel/chain"
