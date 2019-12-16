# frozen_string_literal: true

class User
  def initialize(name:, age:)
    @name, @age = name, age
  end
  attr_reader :name, :age

  def safe
    !underage?
  end

  def errors
    underage? ? [{ age: "underage" }] : nil
  end

  def underage?
    @age <= 18
  end
end
