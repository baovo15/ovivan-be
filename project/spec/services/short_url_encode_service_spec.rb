RSpec.describe Urls::EncodeService do
  let(:original_url) { "https://example.com" }
  let(:form)         { instance_double(UrlForm, url: original_url) }

  before do
    # Default: no cache
    allow(Cache::ShortUrlCache).to receive(:fetch_code_by_original).and_return(nil)
    allow(Cache::ShortUrlCache).to receive(:store)
  end

  describe ".call" do
    it "creates a new ShortUrl when not cached and not existing" do
      expect {
        described_class.call(form)
      }.to change(ShortUrl, :count).by(1)
    end

    it "reuses an existing ShortUrl when original_url already exists" do
      existing = ShortUrl.create!(original_url: original_url, code: "EXIST01")

      expect {
        result = described_class.call(form)
        expect(result).to eq(existing)
      }.not_to change(ShortUrl, :count)
    end

    context "when cache hits" do
      let(:code) { "CACHE01" }

      before do
        allow(Cache::ShortUrlCache).to receive(:fetch_code_by_original)
                                         .with(original_url)
                                         .and_return(code)
      end

      it "returns a ShortUrl based on cached code without creating a new one" do
        expect(ShortUrl).to receive(:find_by).with(code: code).and_return(nil)

        expect {
          result = described_class.call(form)
          expect(result.original_url).to eq(original_url)
          expect(result.code).to eq(code)
        }.not_to change(ShortUrl, :count)
      end
    end
  end
end
