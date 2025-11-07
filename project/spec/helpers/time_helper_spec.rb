# spec/helpers/time_helper_spec.rb
require "rails_helper"

RSpec.describe TimeHelper, type: :helper do
  describe "#format_timestamp" do
    let(:timestamp) { Time.zone.local(2025, 1, 2, 15, 30) } # 2025-01-02 15:30

    it "returns 'N/A' when timestamp is blank" do
      expect(helper.format_timestamp(nil)).to eq("N/A")
    end

    it "formats with :long format" do
      result = helper.format_timestamp(timestamp, format: :long)

      expect(result).to eq(timestamp.strftime("%B %d, %Y %I:%M %p"))
    end

    it "formats with :short format" do
      result = helper.format_timestamp(timestamp, format: :short)

      expect(result).to eq(timestamp.strftime("%d-%m-%Y %H:%M"))
    end

    it "formats with :time_ago format" do
      time = 5.minutes.ago

      result = helper.format_timestamp(time, format: :time_ago)

      # We don’t assert the exact string (depends on current time),
      # just that it contains "ago".
      expect(result).to include("ago")
    end

    it "formats with :custom when custom_format is present" do
      custom_format = "%Y/%m/%d"
      result = helper.format_timestamp(timestamp, format: :custom, custom_format: custom_format)

      expect(result).to eq(timestamp.strftime(custom_format))
    end

    it "returns 'N/A' for :custom when custom_format is nil" do
      result = helper.format_timestamp(timestamp, format: :custom, custom_format: nil)

      expect(result).to eq("N/A")
    end

    it "falls back to timestamp.to_s for unknown format" do
      result = helper.format_timestamp(timestamp, format: :unknown)

      expect(result).to eq(timestamp.to_s)
    end
  end
end
