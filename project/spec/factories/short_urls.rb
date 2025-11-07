FactoryBot.define do
  factory :short_url do
    original_url { "MyText" }
    code { "MyString" }
  end
end
