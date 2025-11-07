# spec/helpers/application_helper_spec.rb
require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  it "includes TimeHelper" do
    expect(ApplicationHelper.included_modules).to include(TimeHelper)
  end

  it "can use format_timestamp from TimeHelper" do
    timestamp = Time.zone.local(2025, 1, 2, 15, 30)

    result = helper.format_timestamp(timestamp, format: :short)

    expect(result).to eq(timestamp.strftime("%d-%m-%Y %H:%M"))
  end
end
