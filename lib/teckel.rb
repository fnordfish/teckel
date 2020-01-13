# frozen_string_literal: true

require "teckel/version"

module Teckel
  class Error < StandardError; end
  class FrozenConfigError < Teckel::Error; end
end

require_relative "teckel/config"
require_relative "teckel/operation"
require_relative "teckel/result"
require_relative "teckel/operation/results"
require_relative "teckel/chain"
