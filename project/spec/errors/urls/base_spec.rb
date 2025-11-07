# spec/errors/article/base_spec.rb
require "rails_helper" # or "spec_helper" if you're not using Rails

RSpec.describe Error::Urls::Base do
  describe "inheritance" do
    it "inherits from Error::Base" do
      expect(described_class < Error::Base).to be true
    end
  end

  describe "#initialize" do
    context "when no arguments are given" do
      subject(:error_object) { described_class.new }

      it "sets the default error code" do
        expect(error_object.error).to eq(:standard_error)
      end

      it "sets the default status" do
        expect(error_object.status).to eq(:service_unavailable)
      end

      it "sets the default message" do
        expect(error_object.message).to eq("User service unavailable")
      end
    end

    context "when custom arguments are given" do
      let(:custom_error)   { :custom_error }
      let(:custom_status)  { :bad_request }
      let(:custom_message) { "Something went wrong" }

      subject(:error_object) do
        described_class.new(custom_error, custom_status, custom_message)
      end

      it "uses the provided error code" do
        expect(error_object.error).to eq(custom_error)
      end

      it "uses the provided status" do
        expect(error_object.status).to eq(custom_status)
      end

      it "uses the provided message" do
        expect(error_object.message).to eq(custom_message)
      end
    end
  end
end
