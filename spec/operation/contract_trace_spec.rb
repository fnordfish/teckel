# frozen_string_literal: true

require 'support/dry_base'
RSpec.describe Teckel::Operation do
  context "contract errors include meaningful trace" do
    module TeckelOperationContractTrace
      DefaultError = Struct.new(:message, :status_code)
      Settings = Struct.new(:fail_it)

      class ApplicationOperation
        include Teckel::Operation

        class Input < Dry::Struct
          attribute :input_data, Types::String
        end

        class Output < Dry::Struct
          attribute :output_data, Types::String
        end

        class Error < Dry::Struct
          attribute :error_data, Types::String
        end

        # Freeze the base class to make sure it's inheritable configuration is not altered
        freeze
      end
    end

    # Hack to get reliable stack traces
    eval <<~RUBY, binding, "operation_success_error.rb"
      module TeckelOperationContractTrace
        class OperationSuccessError < ApplicationOperation
          # Includes a deliberate bug while crating a success output
          def call(input)
            success!(incorrect_key: 1)
          end
        end
      end
    RUBY

    eval <<~RUBY, binding, "operation_simple_success_error.rb"
      module TeckelOperationContractTrace
        class OperationSimpleSuccessError < ApplicationOperation
          # Includes a deliberate bug while crating a success output
          def call(input)
            return { incorrect_key: 1 }
          end
        end
      end
    RUBY

    eval <<~RUBY, binding, "operation_failure_error.rb"
      module TeckelOperationContractTrace
        class OperationFailureError < ApplicationOperation
          # Includes a deliberate bug while crating an error output
          def call(input)
            fail!(incorrect_key: 1)
          end
        end
      end
    RUBY

    eval <<~RUBY, binding, "operation_ok.rb"
      module TeckelOperationContractTrace
        class OperationOk < ApplicationOperation
          def call(input)
            success!(output_data: "all fine")
          end
        end
      end
    RUBY

    eval <<~RUBY, binding, "operation_input_error.rb"
      module TeckelOperationContractTrace
        def self.run_operation(operation)
          operation.call(error_input_data: "failure")
        end
      end
    RUBY

    specify "incorrect success" do
      expect {
        TeckelOperationContractTrace::OperationSuccessError.call(input_data: "ok")
      }.to raise_error(Dry::Struct::Error) { |error|
        expect(error.backtrace).to include /^#{Regexp.escape("operation_success_error.rb:5:in `call'")}$/
      }
    end

    specify "incorrect success via simple return prints warning with class name, but no meaningful trace" do
      expect {
        TeckelOperationContractTrace::OperationSimpleSuccessError.call(input_data: "ok")
      }.to output(
        "[Deprecated] TeckelOperationContractTrace::OperationSimpleSuccessError#call " \
        "Simple return values for Teckel Operations are deprecated. Use `success!` instead.\n"
      ).to_stderr.and raise_error(Dry::Struct::Error)
    end

    specify "incorrect fail" do
      expect {
        TeckelOperationContractTrace::OperationFailureError.call(input_data: "ok")
      }.to raise_error(Dry::Struct::Error) { |error|
        expect(error.backtrace).to include /^#{Regexp.escape("operation_failure_error.rb:5:in `call'")}$/
      }
    end

    specify "incorrect input" do
      operation = TeckelOperationContractTrace::OperationOk

      expect(operation.call(input_data: "ok")).to eq(operation.output[output_data: "all fine"])
      expect {
        TeckelOperationContractTrace.run_operation(operation)
      }.to raise_error(Dry::Struct::Error) { |error|
        expect(error.backtrace).to include /^#{Regexp.escape("operation_input_error.rb:3:in `run_operation'")}$/
      }
    end
  end
end
