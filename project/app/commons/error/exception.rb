module Error
  class Exception < Exception
    attr_reader :status, :error, :message
    def initialize(_error = nil, _status = nil, _message = nil)
      @error = _error || :exception
      @status = _status || :service_unavailable
      @message = _message || "service unavailable"
    end
  end
end
