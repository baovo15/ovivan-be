module Error
  module Urls
    class Base < Error::Base
      attr_reader :status, :error, :message
      def initialize(_error = nil, _status = nil, _message = nil)
        @error = _error || :standard_error
        @status = _status || :service_unavailable
        @message = _message || "User service unavailable"
      end
    end
  end
end
