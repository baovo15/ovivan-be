Nice, you’ve moved way past the “toy” controller, so let’s update all of that sample content to match your **current logic**:

* namespaced API (`/v1/urls/encode`, `/v1/urls/decode`)
* `ShortUrl` with `base_host`
* `UrlForm#extract_code`
* JSON responses:

    * encode → `{ short_url: ... }`
    * decode → `{ original_url: ... }`

I’ll rewrite the sections you posted so you can drop them straight into your docs / code.

---

## 1. Model + Migration (persistence after restart)

### Migration

`db/migrate/20251103000000_create_short_urls.rb`

```ruby
class CreateShortUrls < ActiveRecord::Migration[7.1]
  def change
    create_table :short_urls do |t|
      t.text   :original_url, null: false
      t.string :code,         null: false

      t.timestamps
    end

    add_index :short_urls, :code, unique: true
  end
end
```

### Model

`app/models/short_url.rb`

```ruby
class ShortUrl < ApplicationRecord
  validates :original_url, presence: true, length: { maximum: 2.kilobytes }
  validates :code,         presence: true, uniqueness: true

  before_validation :generate_code, on: :create

  def self.base_host
    ENV.fetch("SHORTLINK_BASE_URL", "http://localhost:3000")
  end

  def short_url
    "#{self.class.base_host}/#{code}"
  end

  private

  def generate_code
    return if code.present?

    loop do
      self.code = SecureRandom.urlsafe_base64(6).tr("-_", "Az")
      break unless ShortUrl.exists?(code: code) # collision handling
    end
  end
end
```

---

## 2. UrlForm (validation + extract_code)

`app/forms/url_form.rb` (or wherever you keep forms)

```ruby
class UrlForm < FormBase
  attr_accessor :url

  validates :url, presence: true
  validate  :url_must_be_valid

  def form_attrs
    { url: url }
  end

  # Extract the short code from a full ShortLink URL,
  # or return the raw value if it's already a code.
  def extract_code
    return url if url.blank?

    begin
      uri  = URI.parse(url)
      base = URI.parse(ShortUrl.base_host)

      if same_origin?(uri, base)
        uri.path.delete_prefix("/").split("/").first
      else
        # treat as raw code if not our shortlink host
        url
      end
    rescue URI::InvalidURIError
      # user sent just "GeAi9K"
      url
    end
  end

  private

  def url_must_be_valid
    return if url.blank?

    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      errors.add(:url, "is not a valid HTTP/HTTPS URL")
    end
  rescue URI::InvalidURIError
    errors.add(:url, "is not a valid URL")
  end

  def same_origin?(u1, u2)
    u1.scheme == u2.scheme &&
      u1.host   == u2.host &&
      normalized_port(u1) == normalized_port(u2)
  end

  def normalized_port(uri)
    uri.port || (uri.scheme == "https" ? 443 : 80)
  end
end
```

---

## 3. Endpoints `/v1/urls/encode` and `/v1/urls/decode` (JSON)

### Routes

`config/routes.rb`

```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "urls/encode", to: "urls#encode"
      post "urls/decode", to: "urls#decode"
    end
  end
end
```

### Controller

`app/controllers/api/v1/urls_controller.rb`

```ruby
module Api
  module V1
    class UrlsController < ApplicationController
      before_action :build_url_form

      # POST /encode
      def encode
        Rails.logger.info log_prefix("encode", "start", params: url_params.to_h)

        if @form.validate! && transaction(-> { @encode_url = Urls::EncodeService.call(@form) })
          Rails.logger.info log_prefix("encode", "success",
                                       url: @form.url,
                                       short_url: safe_short_url(@encode_url))

          return render "urls/encode"
        end

        Rails.logger.warn log_prefix("encode", "invalid_original_url", url: @form.url)
        raise Error::Urls::Encode::InvalidOriginalUrl
      rescue StandardError => e
        Rails.logger.error log_prefix("encode", "exception",
                                      error_class: e.class.name,
                                      message: e.message)
        raise
      end

      # POST /decode
      def decode
        Rails.logger.info log_prefix("decode", "start",
                                     short_url_param: @form.url,
                                     code: @form.extract_code)

        @presenter = short_url_presenter

        if @presenter.short_url.present?
          Rails.logger.info log_prefix("decode", "success",
                                       code: @form.extract_code,
                                       original_url: @presenter.short_url.original_url)

          return render "urls/decode"
        end

        Rails.logger.warn log_prefix("decode", "url_not_found", code: @form.extract_code)
        raise ::Error::Urls::Decode::UrlNotFound
      rescue StandardError => e
        Rails.logger.error log_prefix("decode", "exception",
                                      error_class: e.class.name,
                                      message: e.message)
        raise
      end

      private

      def url_params
        # Require an url from params
        params.require(:url)
        # Get the url from params
        params.permit(:url)
      rescue ActionController::ParameterMissing => e
        Rails.logger.warn("[UrlsController] #{e.message}")
        raise ::Error::General::Http::ParameterMissing.new("#{e.message}")
      end

      def build_url_form
        @form ||= UrlForm.new(url_params)
      end

      def short_url_presenter
        ShortUrls::IndexPresenter.new(code: @form.extract_code) if @form.valid?
      end

      def safe_short_url(record)
        record.respond_to?(:short_url) ? record.short_url : nil
      end
    end
  end
end
```

> `Urls::EncodeService` and `ShortUrls::IndexPresenter` can contain your Redis + DB logic; the controller stays thin and just returns JSON.

---

## 4. Tests for both endpoints (RSpec, updated paths & keys)

`spec/requests/api/v1/urls_spec.rb`

```ruby
require "rails_helper"

RSpec.describe "URL Shortener API", type: :request do
  describe "POST /v1/urls/encode" do
    it "returns a short_url for a valid URL" do
      post "/api/v1/urls/encode", params: { url: "https://example.com/page" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["short_url"]).to match(%r{\Ahttp://})
    end

    it "rejects an invalid URL" do
      post "/api/v1/urls/encode", params: { url: "not-a-url" }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("invalid_url")
    end
  end

  describe "POST /v1/urls/decode" do
    it "returns the original_url when the short URL exists" do
      short = ShortUrl.create!(original_url: "https://example.com")

      post "/api/v1/urls/decode", params: { url: short.short_url }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["original_url"]).to eq("https://example.com")
    end

    it "returns 404 for unknown short URL" do
      post "/api/v1/urls/decode", params: { url: "http://localhost:3000/unknown" }

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("not_found")
    end
  end
end
```

Run:

```bash
bundle exec rspec spec/requests/api/v1/short_urls_spec.rb
```

---

## 5. README.md content (adjusted to new logic)

`README.md`

````markdown
# ShortLink – Ruby URL Shortener

Small URL shortening service implemented in Ruby on Rails.

## Features

- `POST /api/v1/urls/encode` – encode a long URL into a short URL.
- `POST /api/v1/urls/decode` – decode a previously generated short URL back to the original.
- Responses are JSON:
  - Encode: `{ "short_url": "http://your.domain/GeAi9K" }`
  - Decode: `{ "original_url": "https://example.com" }`
- Data is stored in PostgreSQL, so previously encoded URLs survive restarts.
- Redis is used as a cache for `code → original_url` (and optionally `original_url → code`).
- Basic validation, error handling, rate limiting (Rack::Attack), and tests.

## How to run

```bash
# 1. Install dependencies
bundle install

# 2. Set environment variables
# (or use .env / credentials depending on your setup)
export DATABASE_URL=postgres://user:userpassword@postgres:5432/ovivan_db
export JWT_SECRET=e372a5b1b8d7a6c54a991e4a9d3f8c3ea8b4ef02c8f7a9f46df6e5d98ac4b3f6
export REDIS_URL=redis://redis:6379/0
export SHORTLINK_BASE_URL=http://localhost:3000
export RAILS_ENV=development
export SECRET_KEY_BASE=SECRET_KEY_BASE
export RAILS_MASTER_KEY=RAILS_MASTER_KEY

# 3. Setup database
bin/rails db:create db:migrate

# 4. Run tests
bundle exec rspec

# 5. Start the server
bin/rails server
````

### Example requests

```bash
# Encode
curl -X POST http://localhost:3000/api/v1/urls/encode \
  -d "url=https://codesubmit.io/library/react"

# => { "short_url": "http://localhost:3000/GeAi9K" }

# Decode with full URL
curl -X POST http://localhost:3000/api/v1/urls/decode \
  -d "url=http://localhost:3000/GeAi9K"

# => { "original_url": "https://codesubmit.io/library/react" }

# Decode with raw code
curl -X POST http://localhost:3000/api/v1/urls/decode \
  -d "url=GeAi9K"

# => { "original_url": "https://codesubmit.io/library/react" }
```

```

That adjusted content now matches your **namespaced API, form object, model with `base_host`, and JSON contract**. You can paste these snippets into your docs/code and they’ll line up with your current implementation.
```
