# spec/controllers/application_controller_spec.rb
require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    # Define a dummy endpoint so we can call methods
    def index
      render plain: log_prefix("encode", "start")
    end
  end

  describe "#log_prefix" do
    it "returns base string when extra is blank (if branch)" do
      result = controller.send(:log_prefix, "encode", "start", {})

      expect(result).to eq("[UrlsController#encode] start")
    end

    it "returns base string with JSON when extra is present (else branch)" do
      extra = { code: "ABC123" }
      result = controller.send(:log_prefix, "decode", "success", extra)

      expect(result).to eq("[UrlsController#decode] success - #{extra.to_json}")
    end
  end
end