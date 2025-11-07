require 'rails_helper'

RSpec.describe ApplicationPresenter, type: :presenter do
  class TestPresenter < ApplicationPresenter
    attribute :test_attribute
  end

  describe 'attributes' do
    it 'allows setting and getting attributes' do
      presenter = TestPresenter.new(test_attribute: 'sample_value')
      expect(presenter.test_attribute).to eq('sample_value')
    end
  end

  describe 'constants' do
    it 'has a default FIRST_PAGE value' do
      expect(ApplicationPresenter::FIRST_PAGE).to eq(1)
    end
  end
end
