# spec/finders/short_url_finder_spec.rb
require "rails_helper"

RSpec.describe ShortUrlFinder, type: :model do
  let!(:short_url1) do
    ShortUrl.create!(
      original_url: "https://example.com/1",
      code: "CODE001"
    )
  end

  let!(:short_url2) do
    ShortUrl.create!(
      original_url: "https://example.com/2",
      code: "CODE002"
    )
  end

  describe ".call" do
    context "when code is present (Proc if-condition true)" do
      it "returns the matching ShortUrl record" do
        result = described_class.call(code: "CODE001")

        expect(result).to eq(short_url1)
      end
    end

    context "when code is blank (Proc if-condition false)" do
      it "returns the model relation (ShortUrl.all)" do
        result = described_class.call(code: nil)

        # When condition is false, run_rule returns `model`,
        # which starts as `ShortUrl.all` (a Relation).
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to match_array([short_url1, short_url2])
      end
    end

    context "when called with a block" do
      it "yields the instance before calling #call" do
        yielded = nil

        result = described_class.call(code: "CODE001") do |instance|
          yielded = instance
        end

        expect(yielded).to be_a(described_class)
        expect(yielded.code).to eq("CODE001")
        expect(result).to eq(short_url1)
      end
    end
  end
end
