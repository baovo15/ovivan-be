# spec/errors/article/decode/url_not_found_spec.rb
require "rails_helper" # or "spec_helper" if you're not using Rails

RSpec.describe Error::Urls::Decode::UrlNotFound do
  subject(:error_object) { described_class.new }

  it "inherits from Error::Base" do
    expect(described_class < Error::Base).to be true
  end

  it "has the correct error code" do
    expect(error_object.error).to eq(:url_not_found)
  end

  it "has the correct HTTP status" do
    expect(error_object.status).to eq(:not_found)
  end

  it "has the correct message" do
    expect(error_object.message).to eq("Short URL not found")
  end
end
