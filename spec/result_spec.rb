# frozen_string_literal: true

RSpec.describe Waldi::Result do
  let(:failure_value) { "some error" }
  let(:failed_result) { Waldi::Result.new(failure_value, false) }

  let(:success_value) { "some error" }
  let(:successful_result) { Waldi::Result.new(failure_value, true) }

  it { expect(successful_result.successful?).to be(true) }
  it { expect(failed_result.successful?).to be(false) }

  it { expect(successful_result.failure?).to be(false) }
  it { expect(failed_result.failure?).to be(true) }

  it { expect(successful_result.value).to eq(success_value) }
  it { expect(failed_result.value).to eq(failure_value) }

  describe "#success" do
    it { expect(successful_result.success).to eq(success_value) }

    it { expect(failed_result.success).to eq(nil) }
    it { expect(failed_result.success("other")).to eq("other") }
    it { expect(failed_result.success { |value| "Failed: #{value}" } ).to eq("Failed: some error") }
  end

  describe "#failure" do
    it { expect(failed_result.failure).to eq(failure_value) }

    it { expect(successful_result.failure).to eq(nil) }
    it { expect(successful_result.failure("other")).to eq("other") }
    it { expect(successful_result.failure { |value| "Failed: #{value}" } ).to eq("Failed: some error") }
  end
end
