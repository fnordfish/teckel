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
    specify do
      result = TeckelResultTest::MissingResultImplementation["value", true]
      expect { result.successful? }.to raise_error(NotImplementedError)
      expect { result.failure? }.to raise_error(NotImplementedError)
      expect { result.value }.to raise_error(NotImplementedError)
    end
  end
end
