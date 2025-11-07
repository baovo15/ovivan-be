module Cache
  class ShortUrlCache
    CODE_TO_ORIGINAL = "short_url:code:%{code}"
    ORIGINAL_TO_CODE = "short_url:original:%{digest}"
    TTL              = 24.hours

    # code -> original_url
    def self.fetch_original_by_code(code)
      key = CODE_TO_ORIGINAL % { code: code }
      REDIS.get(key)
    end

    # original_url -> code
    def self.fetch_code_by_original(original_url)
      key = ORIGINAL_TO_CODE % { digest: digest(original_url) }
      REDIS.get(key)
    end

    def self.store(record)
      return unless record&.code && record&.original_url

      # 1) code -> original_url
      REDIS.set(
        CODE_TO_ORIGINAL % { code: record.code },
        record.original_url,
        ex: TTL
      )

      # 2) original_url -> code
      REDIS.set(
        ORIGINAL_TO_CODE % { digest: digest(record.original_url) },
        record.code,
        ex: TTL
      )
    end

    def self.digest(str)
      Digest::SHA256.hexdigest(str.to_s)
    end

    private_class_method :digest
  end
end

