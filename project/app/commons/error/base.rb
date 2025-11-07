# app/errors/error/base.rb
module Error
  class Base < StandardError
    attr_reader :status, :error, :message

    def initialize(_error = nil, _status = nil, _message = nil, **kwargs)
      # allow both positional and keyword calls
      error   = _error   || kwargs[:error]
      status  = _status  || kwargs[:status]
      message = _message || kwargs[:message]

      @error   = error   || :standard_error
      @status  = status  || :service_unavailable
      @message = message || "service unavailable"

      super(@message) # optional: pass message to StandardError
    end
  end
end