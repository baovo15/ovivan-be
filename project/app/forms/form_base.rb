class FormBase
  include ActiveModel::Model  # To include validations
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attr_accessor :params

  def initialize(params = {})
    @params = params
    assign_attributes(params)
  end

  def validate!
    assign_attributes(@params)

    # Ensure the valid? method is called to trigger validation
    if valid?
      Rails.logger.info "Validation passed."
      true
    else
      raise_validation_errors
    end
  end

  def assign_attributes(params)
    params.each do |key, value|
      instance_variable_set("@#{key}", value) if respond_to?(key)
    end
  end

  # Raise error if validation fails
  def raise_validation_errors
    if errors.any?
      # Log the full error messages for debugging
      Rails.logger.error errors.full_messages.join(", ")

      # Raise the validation error
      raise Error::Validation::Param::InvalidParams.new(errors.full_messages.join(", "))
    else
      Rails.logger.info "No errors found, skipping raise."
    end
  end
end
