# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

module TeckelResultTest
  class MissingResultImplementation
    include Teckel::Result
    def initialize(value, success); end
  end
end

RSpec.describe Teckel::Result do
  describe "missing initialize" do
    specify "raises NotImplementedError" do
      result = TeckelResultTest::MissingResultImplementation["value", true]
      expect { result.successful? }.to raise_error(NotImplementedError, "Result object does not implement `successful?`")
      expect { result.failure? }.to raise_error(NotImplementedError, "Result object does not implement `successful?`")
      expect { result.value }.to raise_error(NotImplementedError, "Result object does not implement `value`")
    end
  end
end
