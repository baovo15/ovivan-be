# spec/requests/urls_api_spec.rb
require "rails_helper"

RSpec.describe "Shorten URL API", type: :request do
  before do
    # Prevent any real Redis calls in request specs
    allow(Cache::ShortUrlCache).to receive(:fetch_original_by_code).and_return(nil)
    allow(Cache::ShortUrlCache).to receive(:fetch_code_by_original).and_return(nil)
    allow(Cache::ShortUrlCache).to receive(:store)
  end

  describe "POST /v1/urls/encode" do
    let(:original_url) { "http://localhost:3000/AbC123xyqwqwqe232" }

    it "creates or finds a ShortUrl and returns short_url JSON" do
      expect {
        post "/v1/urls/encode",
             params: { url: original_url },
             as: :json
      }.to change(ShortUrl, :count).by(1)

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["success"]).to eq("success")

      short = ShortUrl.last
      expect(body.dig("data", "short_url")).to eq(short.short_url)
    end

    it "reuses an existing ShortUrl for the same original_url" do
      existing = ShortUrl.create!(original_url: original_url, code: "AbC123xy")

      expect {
        post "/v1/urls/encode",
             params: { url: original_url },
             as: :json
      }.not_to change(ShortUrl, :count)

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["success"]).to eq("success")
      expect(body.dig("data", "short_url")).to eq(existing.short_url)
    end
  end

  describe "POST /v1/urls/decode" do
    let!(:short) do
      ShortUrl.create!(
        original_url: "http://localhost:3000/AbC123xy",
        code: "ruUo6anJ"
      )
    end

    it "returns original_url JSON when given a short_url" do
      post "/v1/urls/decode",
           params: { url: short.short_url },  # e.g. "http://localhost:3000/ruUo6anJ"
           as: :json

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["success"]).to eq("success")
      expect(body.dig("data", "original_url")).to eq(short.original_url)
    end
  end
end
