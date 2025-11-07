# spec/presenters/short_urls_index_presenter_spec.rb
require "rails_helper"

RSpec.describe ShortUrls::IndexPresenter, type: :model do
  let(:code)      { "AbCd1234" }
  let(:presenter) { described_class.new(code: code) }

  describe "#short_url" do
    context "when cache hits (fetch_original_by_code returns a value)" do
      let(:original_url) { "https://example.com" }

      before do
        allow(Cache::ShortUrlCache).to receive(:fetch_original_by_code)
                                         .with(code)
                                         .and_return(original_url)
      end

      it "returns a new ShortUrl built from cache and does not hit DB" do
        expect(ShortUrlFinder).not_to receive(:call)
        expect(Cache::ShortUrlCache).not_to receive(:store)

        result = presenter.short_url

        expect(result).to be_a(ShortUrl)
        expect(result.code).to eq(code)
        expect(result.original_url).to eq(original_url)
      end
    end

    context "when cache misses and finder returns a record" do
      let(:record) { instance_double(ShortUrl, present?: true) }

      before do
        allow(Cache::ShortUrlCache).to receive(:fetch_original_by_code)
                                         .with(code)
                                         .and_return(nil)

        allow(ShortUrlFinder).to receive(:call)
                                   .with(code: code)
                                   .and_return(record)

        allow(Cache::ShortUrlCache).to receive(:store)
      end

      it "returns the record from ShortUrlFinder and warms the cache" do
        result = presenter.short_url

        expect(result).to eq(record)
        expect(Cache::ShortUrlCache).to have_received(:store).with(record)
      end
    end

    context "when cache misses and finder returns nil" do
      before do
        allow(Cache::ShortUrlCache).to receive(:fetch_original_by_code)
                                         .with(code)
                                         .and_return(nil)

        allow(ShortUrlFinder).to receive(:call)
                                   .with(code: code)
                                   .and_return(nil)

        allow(Cache::ShortUrlCache).to receive(:store)
      end

      it "returns nil and does not store anything in cache" do
        result = presenter.short_url

        expect(result).to be_nil
        expect(Cache::ShortUrlCache).not_to have_received(:store)
      end
    end

    context "memoization" do
      let(:record) { instance_double(ShortUrl, present?: true) }

      before do
        allow(Cache::ShortUrlCache).to receive(:fetch_original_by_code)
                                         .with(code)
                                         .and_return(nil)

        allow(ShortUrlFinder).to receive(:call)
                                   .with(code: code)
                                   .and_return(record)

        allow(Cache::ShortUrlCache).to receive(:store)
      end

      it "calls ShortUrlFinder only once for multiple calls" do
        2.times { presenter.short_url }

        expect(ShortUrlFinder).to have_received(:call).once
      end
    end
  end
end
