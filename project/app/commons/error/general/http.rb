module Error
  module General::Http
    class InternalServer < Base
      def initialize(message)
        super(:internal_server_error, :internal_server_error, message)
      end
    end

    class ParameterMissing < Base
      def initialize(message)
        super(:parameter_missing, :bad_request, message)
      end
    end

  end
end
