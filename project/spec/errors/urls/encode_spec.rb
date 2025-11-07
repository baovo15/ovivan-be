# spec/errors/urls/encode/invalid_original_url_spec.rb
require "rails_helper" # or "spec_helper" if not using Rails

RSpec.describe Error::Urls::Encode::InvalidOriginalUrl do
  subject(:error_object) { described_class.new }

  it "inherits from Error::Urls::Encode::Base" do
    expect(described_class < Error::Urls::Base).to be true
  end

  it "has the correct error code" do
    expect(error_object.error).to eq(:invalid_original_url)
  end

  it "has the correct HTTP status" do
    expect(error_object.status).to eq(:unprocessable_entity)
  end

  it "has the correct message" do
    expect(error_object.message).to eq("Original URL is invalid")
  end
end
