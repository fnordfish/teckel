# frozen_string_literal: true

require_relative "teckel/version"

module Teckel
  # Base error class for this lib
  class Error < StandardError; end

  # configuring the same value twice will raise this
  class FrozenConfigError < Teckel::Error; end

  # missing important configurations (like contracts) will raise this
  class MissingConfigError < Teckel::Error; end

  DEFAULT_CONSTRUCTOR = :[]

  # @!visibility private
  UNDEFINED = Object.new.freeze
end

require_relative "teckel/config"
require_relative "teckel/contracts"
require_relative "teckel/result"
require_relative "teckel/operation"
