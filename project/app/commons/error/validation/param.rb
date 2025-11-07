module Error
  module Validation::Param
    class InvalidParams < Base
      def initialize(message)
        super(:params_invalid, :unprocessable_entity, message)
      end
    end
  end
end
