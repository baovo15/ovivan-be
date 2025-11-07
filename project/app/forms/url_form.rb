class UrlForm < FormBase
  include ActiveModel::Validations

  attr_accessor :url, :content

  # 1. Presence
  validates :url, presence: true

  # 2. Format must be a valid HTTP/HTTPS URL
  validate :url_must_be_valid

  def initialize(params = {})
    super(params)
  end

  def form_attrs
    {
      url: url
    }
  end

  # ---- Business helpers ------------------------------------------------------

  # used in decode to get "GeAi9K" from "http://your.domain/GeAi9K"
  def extract_code
    return url if url.blank?

    uri  = URI.parse(url)
    base = URI.parse(ShortUrl.base_host)

    if same_origin?(uri, base)
      # "/GeAi9K" -> "GeAi9K"
      uri.path.delete_prefix("/").split("/").first
    else
      # if it's not our shortener domain, assume user sent a raw code
      url
    end
  rescue URI::InvalidURIError
    # if client sends just "GeAi9K" (not a URL) → treat as raw code
    url
  end

  def valid_url?(value)
    uri = URI.parse(value)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end


  private

  def same_origin?(u1, u2)
    u1.scheme == u2.scheme &&
      u1.host   == u2.host &&
      normalized_port(u1) == normalized_port(u2)
  end

  def normalized_port(uri)
    uri.port || (uri.scheme == "https" ? 443 : 80)
  end

  def url_must_be_valid
    return if url.blank?          # let presence validator handle this
    return if valid_url?(url)

    errors.add(:url, "is not a valid HTTP/HTTPS URL")
  end
end
