class ShortUrl < ApplicationRecord
  validates :original_url, presence: true, length: { maximum: 2.kilobytes }
  validates :code, presence: true, uniqueness: true

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
      self.code = SecureRandom.alphanumeric(8)
      break unless ShortUrl.exists?(code: code) # collision handling
    end
  end
end
