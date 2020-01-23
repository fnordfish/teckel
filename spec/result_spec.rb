# frozen_string_literal: true

require 'support/dry_base'
require 'support/fake_models'

RSpec.describe Teckel::Result do
  describe "missing initialize" do
    class MissingResultImplementation
      include Teckel::Result
      def initialize(value, success); end
    end

    specify do
      result = MissingResultImplementation["value", true]
      expect { result.successful? }.to raise_error(NotImplementedError)
      expect { result.failure? }.to raise_error(NotImplementedError)
      expect { result.value }.to raise_error(NotImplementedError)
    end
  end
end
