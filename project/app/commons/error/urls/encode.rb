module Error
  module Urls
    module Encode
      class InvalidOriginalUrl < Error::Urls::Base
        def initialize
          super(
            :invalid_original_url,     # _error
            :unprocessable_entity,     # _status
            "Original URL is invalid"  # _message
          )
        end
      end
    end
  end
end
