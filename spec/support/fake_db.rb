# frozen_string_literal: true

module FakeDB
  Rollback = Class.new(RuntimeError)

  def self.transaction
    yield
  rescue Rollback # standard:disable Lint/UselessRescue
    # doing rollback ...
    raise
  end
end
