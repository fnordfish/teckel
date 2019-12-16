# frozen_string_literal: true

require "waldi/version"

module Waldi
  class Error < StandardError; end
end

require_relative "waldi/config"
require_relative "waldi/operation"
require_relative "waldi/result"
require_relative "waldi/operation/results"
require_relative "waldi/chain"
