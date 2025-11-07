# spec/errors/error_handler_spec.rb
require "rails_helper"

RSpec.describe Error::Handler, type: :controller do
  controller(ApplicationController) do
    include Error::Handler

    def raise_standard
      raise StandardError, "unexpected failure"
    end

    def raise_custom
      raise Error::Base.new(:custom_error, :unprocessable_entity, "Custom failure")
    end
  end

  before do
    routes.draw do
      get "raise_standard" => "anonymous#raise_standard"
      get "raise_custom"   => "anonymous#raise_custom"
    end
  end

  describe "handling StandardError" do
    it "wraps it as InternalServer error and returns 500" do
      get :raise_standard, as: :json

      expect(response).to have_http_status(:internal_server_error)

      # Option 1: check instance variables set by `respond`
      msg   = controller.instance_variable_get(:@message)
      error = controller.instance_variable_get(:@error)

      expect(msg).to include("unexpected failure")
      # depending on your InternalServer implementation, could be e.g. :internal_server_error
      expect(error).not_to be_nil
    end
  end

  describe "handling custom Error::Base exceptions" do
    it "renders the specific error with its status and message" do
      get :raise_custom, as: :json

      expect(response).to have_http_status(:unprocessable_entity)

      error = controller.instance_variable_get(:@error)
      msg   = controller.instance_variable_get(:@message)

      expect(error).to eq(:custom_error)
      expect(msg).to eq("Custom failure")
    end
  end
end
