# spec/forms/url_form_spec.rb
require "rails_helper"

RSpec.describe UrlForm do
  describe "validations" do
    it "is invalid when url is blank (presence validation)" do
      form = described_class.new(url: "")

      expect(form).not_to be_valid
      expect(form.errors[:url]).to include("can't be blank")
    end

    it "is valid when url is a proper HTTP/HTTPS URL" do
      form = described_class.new(url: "https://example.com")

      expect(form).to be_valid
    end

    it "is invalid when url is not a valid HTTP/HTTPS URL" do
      form = described_class.new(url: "not-a-url")

      expect(form).not_to be_valid
      expect(form.errors[:url]).to include("is not a valid HTTP/HTTPS URL")
    end
  end

  describe "#form_attrs" do
    it "returns a hash with url" do
      form = described_class.new(url: "https://example.com")

      expect(form.form_attrs).to eq(url: "https://example.com")
    end
  end

  describe "#valid_url?" do
    let(:form) { described_class.new }

    it "returns true for HTTP URL" do
      expect(form.valid_url?("http://example.com")).to be true
    end

    it "returns true for HTTPS URL" do
      expect(form.valid_url?("https://example.com")).to be true
    end

    it "returns false for invalid URL string" do
      expect(form.valid_url?("not-a-url")).to be false
    end

    it "returns false for URI.parse errors" do
      # something URI.parse will reject
      expect(form.valid_url?("http://exa mple.com")).to be false
    end
  end

  describe "#extract_code" do
    let(:base_host) { "http://short.test" }

    before do
      allow(ShortUrl).to receive(:base_host).and_return(base_host)
    end

    context "when url is blank" do
      it "returns the blank url" do
        form = described_class.new(url: "")

        expect(form.extract_code).to eq("")
      end
    end

    context "when url is from the same origin as ShortUrl.base_host" do
      it "extracts the first path segment as code from '/code'" do
        form = described_class.new(url: "#{base_host}/GeAi9K")

        expect(form.extract_code).to eq("GeAi9K")
      end

      it "extracts the first segment when there are extra path parts" do
        form = described_class.new(url: "#{base_host}/GeAi9K/extra/path")

        expect(form.extract_code).to eq("GeAi9K")
      end
    end

    context "when url is from a different origin" do
      it "returns the original url unchanged (assumes user sent raw code / other url)" do
        original = "https://other-host.com/whatever"
        form     = described_class.new(url: original)

        expect(form.extract_code).to eq(original)
      end
    end

    context "when url is just a code (not a URL at all)" do
      it "returns the raw code" do
        form = described_class.new(url: "GeAi9K")

        expect(form.extract_code).to eq("GeAi9K")
      end
    end

    context "when url raises URI::InvalidURIError" do
      it "returns the raw value" do
        # something that blows up URI.parse
        raw = "http://exa mple.com/Weird Code"
        form = described_class.new(url: raw)

        expect(form.extract_code).to eq(raw)
      end
    end
  end

  describe "#normalized_port" do
    let(:form) { described_class.new }

    it "returns the explicit port when uri.port is present" do
      uri = URI.parse("https://example.com:8443")

      expect(form.send(:normalized_port, uri)).to eq(8443)
    end

    it "returns 443 for https when no port is specified" do
      uri = URI.parse("https://example.com")

      expect(form.send(:normalized_port, uri)).to eq(443)
    end

    it "returns 80 for http when no port is specified" do
      uri = URI.parse("http://example.com")

      expect(form.send(:normalized_port, uri)).to eq(80)
    end
  end

end
