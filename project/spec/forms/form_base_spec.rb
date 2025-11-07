require 'rails_helper'

RSpec.describe FormBase, type: :model do
  class TestForm < FormBase
    attr_accessor :name, :email

    validates :name, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  end

  describe '#initialize' do
    it 'assigns attributes correctly' do
      params = { name: 'John Doe', email: 'john.doe@example.com' }
      form = TestForm.new(params)

      expect(form.name).to eq('John Doe')
      expect(form.email).to eq('john.doe@example.com')
    end
  end

  describe '#validate!' do
    context 'when valid parameters are provided' do
      it 'passes validation and returns true' do
        params = { name: 'John Doe', email: 'john.doe@example.com' }
        form = TestForm.new(params)

        expect(form.validate!).to be true
      end
    end

    context 'when invalid parameters are provided' do
      it 'raises an error for missing required fields' do
        params = { name: '', email: '' }
        form = TestForm.new(params)

        expect { form.validate! }.to raise_error(Error::Validation::Param::InvalidParams)
      end

      it 'raises an error for invalid email format' do
        params = { name: 'John Doe', email: 'invalid-email' }
        form = TestForm.new(params)

        expect { form.validate! }.to raise_error(Error::Validation::Param::InvalidParams, /Email is invalid/)
      end
    end
  end

  describe '#assign_attributes' do
    it 'assigns attributes dynamically' do
      form = TestForm.new(name: 'Initial Name', email: 'initial@example.com')
      form.assign_attributes(name: 'Updated Name', email: 'updated@example.com')

      expect(form.name).to eq('Updated Name')
      expect(form.email).to eq('updated@example.com')
    end
  end

  describe '#raise_validation_errors' do
    it 'logs errors and raises an exception when validation fails' do
      params = { name: '', email: 'invalid' }
      form = TestForm.new(params)
      form.valid?

      expect(Rails.logger).to receive(:error).with(/Name can't be blank, Email is invalid/)
      expect { form.raise_validation_errors }.to raise_error(Error::Validation::Param::InvalidParams)
    end

    it 'logs info and skips raise when no validation errors' do
      form = TestForm.new(name: 'Valid', email: 'valid@example.com')
      form.valid? # should populate errors as empty

      expect(Rails.logger).to receive(:info).with("No errors found, skipping raise.")
      expect { form.raise_validation_errors }.not_to raise_error
    end
  end
end
