module Transaction
  module Handler
    extend ActiveSupport::Concern

    # transaction
    # @param callable callable
    # @return bool
    def transaction(callable)
      ApplicationRecord.transaction do
        begin
          return callable.call()
        rescue StandardError => e
          Rails.logger.error("Transaction failed: #{e.message}")
          raise e  # Re-raise the error to be handled by `rescue_from`
        end
      end
    end
  end
end
