# app/presenters/short_urls/index_presenter.rb
module ShortUrls
  class IndexPresenter < ApplicationPresenter
    attribute :code

    def short_url
      @short_url ||= fetch_short_url
    end

    private

    def fetch_short_url
      # Try Redis cache
      if (original = Cache::ShortUrlCache.fetch_original_by_code(code))
        Rails.logger.info("[ShortUrls::IndexPresenter] cache_hit code=#{code}")
        return ShortUrl.new(code: code, original_url: original)
      end

      Rails.logger.info("[ShortUrls::IndexPresenter] cache_miss code=#{code}")

      # Fallback to DB via Finder
      record = ShortUrlFinder.call(code: code)

      # Warm cache for next time
      Cache::ShortUrlCache.store(record) if record.present?

      record
    end
  end
end
