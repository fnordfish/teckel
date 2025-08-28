# frozen_string_literal: true

RSpec.describe Teckel do
  it "has a version number" do
    expect(Teckel.const_defined?(:VERSION)).to be true
    expect(Teckel::VERSION).not_to be nil
  end
end
