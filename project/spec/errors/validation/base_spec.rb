require 'rails_helper'

RSpec.describe Error::Validation::Base do
  describe "#initialize" do
    context "when initialized without arguments" do
      let(:error) { described_class.new }

      it "has a default error type" do
        expect(error.error).to eq(:standard_error)
      end

      it "has a default status of :service_unavailable" do
        expect(error.status).to eq(:service_unavailable)
      end

      it "has a default message" do
        expect(error.message).to eq("Validation service unavailable")
      end
    end

    context "when initialized with custom values" do
      let(:error) { described_class.new(:validation_error, :unprocessable_entity, "Invalid validation data") }

      it "sets the custom error type" do
        expect(error.error).to eq(:validation_error)
      end

      it "sets the custom status" do
        expect(error.status).to eq(:unprocessable_entity)
      end

      it "sets the custom message" do
        expect(error.message).to eq("Invalid validation data")
      end
    end
  end

  describe "#raise behavior" do
    it "raises an exception with a custom message" do
      expect { raise Error::Validation::Base.new(:invalid_format, :bad_request, "Format not accepted") }
        .to raise_error(Error::Validation::Base, "Format not accepted")
    end
  end
end
