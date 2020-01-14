# frozen_string_literal: true

module Teckel
  # Simple type object for enforcing +input+, +output+ or +error+ data to be
  # not set (or +nil+)
  class None
    class << self
      # Always return nil
      # @return nil
      # @raise [ArgumentError] when called with any non-nil arguments
      def [](*args)
        raise ArgumentError, "None called with arguments" if args.any?(&:itself)
      end

      alias :new :[]
    end
  end
end
