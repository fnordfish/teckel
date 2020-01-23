# frozen_string_literal: true

module Teckel
  module Chain
    # Internal wrapper of a step definition
    Step = Struct.new(:name, :operation) do
      def finalize!
        name.freeze
        operation.finalize!
        freeze
      end

      def with(settings)
        self.class.new(name, operation.with(settings))
      end
    end
  end
end
