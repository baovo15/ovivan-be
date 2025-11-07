require 'rails_helper'

RSpec.describe Error::Validation::Param::InvalidParams do
  describe "#initialize" do
    let(:error_message) { "Invalid parameters provided" }
    let(:error) { described_class.new(error_message) }

    it "sets the correct error type" do
      expect(error.error).to eq(:params_invalid)
    end

    it "sets the correct status" do
      expect(error.status).to eq(:unprocessable_entity)
    end

    it "sets the provided error message" do
      expect(error.message).to eq(error_message)
    end
  end

  describe "#raise behavior" do
    it "raises an exception with a custom message" do
      expect { raise Error::Validation::Param::InvalidParams.new("Invalid request format") }
        .to raise_error(Error::Validation::Param::InvalidParams, "Invalid request format")
    end
  end
end
