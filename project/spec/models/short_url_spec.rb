require "rails_helper"

RSpec.describe ShortUrl, type: :model do
  describe ".base_host" do
    let(:env_key) { "SHORTLINK_BASE_URL" }

    it "returns ENV value when set" do
      original = ENV[env_key]
      ENV[env_key] = "https://custom.domain"

      expect(described_class.base_host).to eq("https://custom.domain")
    ensure
      ENV[env_key] = original
    end

    it "returns default when ENV not set" do
      original = ENV.delete(env_key)
      expect(described_class.base_host).to eq("http://localhost:3000")
    ensure
      ENV[env_key] = original if original
    end
  end

  describe "#generate_code" do
    it "skips generation if code already present (return branch)" do
      short = described_class.new(original_url: "https://example.com", code: "EXISTING")
      expect(SecureRandom).not_to receive(:alphanumeric)

      short.send(:generate_code)
      expect(short.code).to eq("EXISTING")
    end

    it "retries on collision (branch: exists? == true once)" do
      short = described_class.new(original_url: "https://example.com")

      # 1st generated code collides, 2nd is unique
      allow(SecureRandom).to receive(:alphanumeric)
                               .with(8)
                               .and_return("DUPLCODE", "UNIQUECD")

      allow(ShortUrl).to receive(:exists?)
                           .with(code: "DUPLCODE").and_return(true)
      allow(ShortUrl).to receive(:exists?)
                           .with(code: "UNIQUECD").and_return(false)

      short.send(:generate_code)
      expect(short.code).to eq("UNIQUECD")
    end
  end
end
