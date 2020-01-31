# frozen_string_literal: true

RSpec.describe Teckel::Operation do
  context "default settings via base class" do
    module TeckelOperationDefaultsViaBaseClass
      DefaultError = Struct.new(:message, :status_code)
      Settings = Struct.new(:fail_it)

      class ApplicationOperation
        include Teckel::Operation

        settings Settings
        settings_constructor ->(data) { settings.new(*data.values_at(*settings.members)) }

        error DefaultError
        error_constructor ->(data) { error.new(*data.values_at(*error.members)) }

        result!

        # Freeze the base class to make sure it's inheritable configuration is not altered
        freeze
      end

      class OperationA < ApplicationOperation
        input Struct.new(:input_data_a)
        output Struct.new(:output_data_a)

        def call(input)
          if settings&.fail_it
            fail!(message: settings.fail_it, status_code: 400)
          else
            input.input_data_a * 2
          end
        end

        finalize!
      end

      class OperationB < ApplicationOperation
        input Struct.new(:input_data_b)
        output Struct.new(:output_data_b)

        def call(input)
          if settings&.fail_it
            fail!(message: settings.fail_it, status_code: 500)
          else
            input.input_data_b * 4
          end
        end

        finalize!
      end
    end

    let(:operation_a) { TeckelOperationDefaultsViaBaseClass::OperationA }
    let(:operation_b) { TeckelOperationDefaultsViaBaseClass::OperationB }

    it "inherits config" do
      expect(operation_a.result).to eq(Teckel::Operation::Result)
      expect(operation_a.settings).to eq(TeckelOperationDefaultsViaBaseClass::Settings)

      expect(operation_b.result).to eq(Teckel::Operation::Result)
      expect(operation_b.settings).to eq(TeckelOperationDefaultsViaBaseClass::Settings)
    end

    context "operation_a" do
      it "can run" do
        result = operation_a.call(10)
        expect(result.success.to_h).to eq(output_data_a: 20)
      end

      it "can fail" do
        result = operation_a.with(fail_it: "D'oh!").call(10)
        expect(result.failure.to_h).to eq(
          message: "D'oh!", status_code: 400
        )
      end
    end

    context "operation_b" do
      it "can run" do
        result = operation_b.call(10)
        expect(result.success.to_h).to eq(output_data_b: 40)
      end

      it "can fail" do
        result = operation_b.with(fail_it: "D'oh!").call(10)
        expect(result.failure.to_h).to eq(
          message: "D'oh!", status_code: 500
        )
      end
    end
  end
end
