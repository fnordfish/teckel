# frozen_string_literal: true

RSpec.describe Teckel::Operation::Result do
  let(:failure_value) { "some error" }
  let(:failed_result) { Teckel::Operation::Result.new(failure_value, false) }

  let(:success_value) { "some success" }
  let(:successful_result) { Teckel::Operation::Result.new(success_value, true) }

  it { expect(successful_result.successful?).to eq(true) }
  it { expect(failed_result.successful?).to eq(false) }

  it { expect(successful_result.failure?).to eq(false) }
  it { expect(failed_result.failure?).to eq(true) }

  it { expect(successful_result.value).to eq(success_value) }
  it { expect(failed_result.value).to eq(failure_value) }

  describe "#success" do
    it("on successful result, returns value") {
      expect(successful_result.success).to eq(success_value)
    }

    describe "on failed result" do
      it("with no fallbacks, returns nil") {
        expect(failed_result.success).to eq(nil)
      }
      it("with default-argument, returns default-argument") {
        expect(failed_result.success("other")).to eq("other")
      }
      it("with block, returns block return value") {
        expect(failed_result.success { |value| "Failed: #{value}" } ).to eq("Failed: some error")
      }
      it("with default-argument and block given, returns default-argument, skips block") {
        expect { |blk|
          expect(failed_result.success("default", &blk)).to_not eq("default")
        }.to(yield_control)
      }
    end
  end

  describe "#failure" do
    it { expect(failed_result.failure).to eq(failure_value) }

    it { expect(successful_result.failure).to eq(nil) }
    it { expect(successful_result.failure("other")).to eq("other") }
    it { expect(successful_result.failure { |value| "Failed: #{value}" } ).to eq("Failed: some success") }
  end
end
