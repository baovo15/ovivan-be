module TimeHelper
  def format_timestamp(timestamp, format: :long, custom_format: nil)
    return "N/A" if timestamp.blank?

    case format
    when :long
      timestamp.strftime("%B %d, %Y %I:%M %p")
    when :short
      timestamp.strftime("%d-%m-%Y %H:%M")
    when :time_ago
      time_ago_in_words(timestamp) + " ago"
    when :custom
      return timestamp.strftime(custom_format) if custom_format.present?
      "N/A"
    else
      timestamp.to_s
    end
  end
end
