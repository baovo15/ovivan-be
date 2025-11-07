module Error
  module Handler
    extend ActiveSupport::Concern

    included do
      self.class_eval do
        rescue_from ::Exception do |e|
          # puts e.to_yaml if Rails.env.development?
          case e
          when Error::Base, Error::Exception
          else
            e = Error::General::Http::InternalServer.new(e.message)
          end
          respond(e.error, e.status, e.message)
        end
      end
    end

    private

    # respond
    # @param _error string, _status int, _message string
    # @return json
    def respond(_error, _status, _message)
      @error = _error
      @message = _message
      render "application/error", status: _status, formats: [:json]
    end
  end
end
