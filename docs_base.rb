# frozen_string_literal: true

require "English"
require 'dry-types'
require 'dry-struct'

Warning[:experimental] = false if Warning.respond_to? :[]

module Types
  include Dry.Types()
end

module FakeDB
  Rollback = Class.new(RuntimeError)

  def self.transaction
    yield
  rescue Rollback
    # doing rollback ...
    raise
  end
end

class User
  def initialize(name:, age:)
    @name, @age = name, age
  end
  attr_reader :name, :age

  def save
    !underage?
  end

  def errors
    underage? ? [{ age: "underage" }] : nil
  end

  def underage?
    @age <= 18
  end
end
