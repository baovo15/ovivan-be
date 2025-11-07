module Urls
  class EncodeService < ApplicationService
    attr_reader :form

    def initialize(form)
      @form = form
    end

    private

    def call
      original = form.url

      # 1) Try cache (original_url -> code)
      if (code = Cache::ShortUrlCache.fetch_code_by_original(original))
        Rails.logger.info("[EncodeService] cache_hit original_url=#{original}")
        return ShortUrl.find_by(code: code) || ShortUrl.new(original_url: original, code: code)
      end

      Rails.logger.info("[EncodeService] cache_miss original_url=#{original}")

      # 2) DB as source of truth
      record = ShortUrl.find_or_initialize_by(original_url: original)
      if record.new_record?
        record.code = generate_code
        record.save!
        Rails.logger.info("[EncodeService] created short_url=#{record.short_url}")
      else
        Rails.logger.info("[EncodeService] reused existing short_url=#{record.short_url}")
      end

      # 3) Write-through cache
      Cache::ShortUrlCache.store(record)

      record
    end

    def generate_code
      loop do
        code = SecureRandom.urlsafe_base64(6).tr("-_", "Az")
        break code unless ShortUrl.exists?(code: code)
      end
    end
  end
end
