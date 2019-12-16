# frozen_string_literal: true

module Waldi
  class Config
    class FrozenConfigError < Waldi::Error; end

    @default_constructor = :[]
    class << self
      def default_constructor(sym_or_proc = nil)
        return @default_constructor if sym_or_proc.nil?

        @default_constructor = sym_or_proc
      end
    end

    def initialize
      @input_class = nil
      @input_constructor = nil

      @output_class = nil
      @output_constructor = nil

      @error_class = nil
      @error_constructor = nil
    end

    def input(klass = nil)
      return @input_class if klass.nil?
      raise FrozenConfigError unless @input_class.nil?

      @input_class = klass
    end

    def input_constructor(sym_or_proc = nil)
      return (@input_constructor || self.class.default_constructor) if sym_or_proc.nil?
      raise FrozenConfigError unless @input_constructor.nil?

      @input_constructor = sym_or_proc
    end

    def output(klass = nil)
      return @output_class if klass.nil?
      raise FrozenConfigError unless @output_class.nil?

      @output_class = klass
    end

    def output_constructor(sym_or_proc = nil)
      return (@output_constructor || self.class.default_constructor) if sym_or_proc.nil?
      raise FrozenConfigError unless @output_constructor.nil?

      @output_constructor = sym_or_proc
    end

    def error(klass = nil)
      return @error_class if klass.nil?
      raise FrozenConfigError unless @error_class.nil?

      @error_class = klass
    end

    def error_constructor(sym_or_proc = nil)
      return (@error_constructor || self.class.default_constructor) if sym_or_proc.nil?
      raise FrozenConfigError unless @error_constructor.nil?

      @error_constructor = sym_or_proc
    end
  end
end
