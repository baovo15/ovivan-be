# spec/cache/short_url_cache_spec.rb
require "rails_helper"

RSpec.describe Cache::ShortUrlCache do
  let(:redis) { instance_double("Redis") }

  before do
    # Replace the global REDIS constant with a test double
    stub_const("REDIS", redis)
  end

  describe ".fetch_original_by_code" do
    let(:code)         { "AbCd1234" }
    let(:redis_key)    { "short_url:code:#{code}" }
    let(:original_url) { "https://example.com" }

    it "builds the correct key and reads it from Redis" do
      expect(redis).to receive(:get).with(redis_key).and_return(original_url)

      result = described_class.fetch_original_by_code(code)
      expect(result).to eq(original_url)
    end
  end

  describe ".fetch_code_by_original" do
    let(:original_url) { "https://example.com" }
    let(:digest)       { Digest::SHA256.hexdigest(original_url) }
    let(:redis_key)    { "short_url:original:#{digest}" }
    let(:code)         { "AbCd1234" }

    it "builds the correct key using the digest and reads it from Redis" do
      expect(redis).to receive(:get).with(redis_key).and_return(code)

      result = described_class.fetch_code_by_original(original_url)
      expect(result).to eq(code)
    end
  end

  describe ".store" do
    let(:code)         { "AbCd1234" }
    let(:original_url) { "https://example.com" }
    let(:ttl)          { described_class::TTL }

    let(:record) do
      instance_double(
        ShortUrl,
        code: code,
        original_url: original_url
      )
    end

    let(:code_key) do
      "short_url:code:#{code}"
    end

    let(:digest) do
      Digest::SHA256.hexdigest(original_url)
    end

    let(:original_key) do
      "short_url:original:#{digest}"
    end

    context "when record has both code and original_url" do
      it "writes both code->original_url and original_url->code entries to Redis with TTL" do
        expect(redis).to receive(:set).with(code_key, original_url, ex: ttl)
        expect(redis).to receive(:set).with(original_key, code, ex: ttl)

        described_class.store(record)
      end
    end

    context "when record is nil" do
      it "does nothing" do
        expect(redis).not_to receive(:set)

        described_class.store(nil)
      end
    end

    context "when record has no code" do
      let(:record) do
        instance_double(ShortUrl, code: nil, original_url: original_url)
      end

      it "does nothing" do
        expect(redis).not_to receive(:set)

        described_class.store(record)
      end
    end

    context "when record has no original_url" do
      let(:record) do
        instance_double(ShortUrl, code: code, original_url: nil)
      end

      it "does nothing" do
        expect(redis).not_to receive(:set)

        described_class.store(record)
      end
    end
  end

  describe ".digest" do
    it "returns a SHA256 hex digest of the given string" do
      expect(described_class.send(:digest, "foo"))
        .to eq(Digest::SHA256.hexdigest("foo"))
    end
  end
end
