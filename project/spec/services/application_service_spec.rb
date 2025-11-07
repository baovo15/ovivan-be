require 'rails_helper'

RSpec.describe ApplicationService, type: :service do
  # A concrete service that works properly
  class TestService < ApplicationService
    private

    def initialize(param)
      @param = param
    end

    def call
      "Processed: #{@param}"
    end
  end

  # A service with no call method
  class InvalidService < ApplicationService; end

  describe '.call' do
    it 'invokes the service with given arguments' do
      result = TestService.call('input')
      expect(result).to eq('Processed: input')
    end

    it 'yields the instance if block is given' do
      yielded = nil
      result = TestService.call('input') { |instance| yielded = instance }
      expect(yielded).to be_a(TestService)
      expect(result).to eq('Processed: input')
    end

    it 'raises NotImplementedError when call is not defined' do
      expect { InvalidService.call }.to raise_error(NotImplementedError)
    end
  end

  describe '#to_proc' do
    it 'returns a proc of the call method and works with it' do
      instance = nil
      TestService.call('input') { |i| instance = i }
      callable = instance.to_proc

      expect(callable.call).to eq('Processed: input')
    end
  end


  describe '#initialize' do
    it 'returns if args are empty' do
      service = Class.new(ApplicationService) do
        private

        def initialize(*args)
          super
        end

        def call
          "called"
        end
      end

      expect {
        service.call
      }.not_to raise_error
    end

    it 'raises NotImplementedError when args are passed but not handled' do
      service = Class.new(ApplicationService) do
        private

        def initialize(*args)
          super
        end

        def call
          "called"
        end
      end

      expect {
        service.call("unexpected")
      }.to raise_error(NotImplementedError)
    end
  end

  describe '#call (base class)' do
    it 'raises NotImplementedError if not implemented' do
      service = InvalidService.allocate
      expect {
        service.send(:call)
      }.to raise_error(NotImplementedError)
    end
  end
end
