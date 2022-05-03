# frozen_string_literal: true

module Teckel
  module Contracts
    # Simple contract for enforcing data to be not set or +nil+
    module None
      class << self
        # Always return +nil+
        # @return [NilClass]
        # @raise [ArgumentError] when called with any non-nil arguments
        def [](*args)
          raise ArgumentError, "None called with arguments" if args.any?(&:itself)
        end

        alias :new :[]
      end
    end
  end
end
