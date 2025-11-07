require 'rails_helper'

RSpec.describe Error::Exception do
  describe "#initialize" do
    context "when initialized with no arguments" do
      let(:error) { described_class.new }

      it "has a default error type" do
        expect(error.error).to eq(:exception)
      end

      it "has a default status of :service_unavailable" do
        expect(error.status).to eq(:service_unavailable)
      end

      it "has a default message" do
        expect(error.message).to eq("service unavailable")
      end
    end

    context "when initialized with custom values" do
      let(:error) { described_class.new(:custom_error, :bad_request, "Something went wrong") }

      it "sets the custom error type" do
        expect(error.error).to eq(:custom_error)
      end

      it "sets the custom status" do
        expect(error.status).to eq(:bad_request)
      end

      it "sets the custom message" do
        expect(error.message).to eq("Something went wrong")
      end
    end
  end

  describe "#raise behavior" do
    it "raises an exception with a custom message" do
      expect { raise Error::Exception.new(:not_found, :not_found, "Record not found") }
        .to raise_error(Error::Exception, "Record not found")
    end
  end
end
