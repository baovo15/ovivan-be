# typed: false
# frozen_string_literal: true

class ApplicationService
  private_class_method :new

  def self.call(*args)
    instance = new(*args)
    yield(instance) if block_given?
    instance.send(:call)
  end

  def to_proc
    method(:call).to_proc
  end

  private

  def initialize(*args)
    return if args.empty?

    raise(NotImplementedError, "You must implement #{self.class}##{__method__}")
  end

  def call
    raise(NotImplementedError, "You must implement #{self.class}##{__method__}")
  end
end
