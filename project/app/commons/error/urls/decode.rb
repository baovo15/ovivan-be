module Error
  module Urls::Decode
    class UrlNotFound < Base
      def initialize
        super(
          error:   :url_not_found,
          status:  :not_found,
          message: "Short URL not found"
        )
      end
    end

  end
end
