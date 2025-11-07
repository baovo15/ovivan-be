class ApplicationFinder
  include ActiveModel::Model
  include ActiveModel::Attributes

  private_class_method :new

  class_attribute :model
  class_attribute :rules, default: []

  class << self
    def model(model)
      self.model = model.all
    end

    def inherited(subclass)
      subclass.rules = []
    end

    def call(*args)
      instance = new(*args)
      yield(instance) if block_given?
      instance.send(:call)
    end

    def rule(method_name, options = {})
      rules.push(method_name: method_name, options: options)
    end
  end

  private

  delegate :arel_table, to: :model

  def call
    rules.each do |rule|
      self.model = run_rule(rule)
    end

    model
  end

  def run_rule(rule)
    if rule[:options].key?(:if)
      if if_condition(rule[:options][:if])
        send(rule[:method_name])
      else
        model
      end
    else
      send(rule[:method_name])
    end
  end

  def if_condition(cond)
    case cond
    when Symbol
      send(cond)
    when Proc
      instance_exec(&cond)
    end
  end
end
