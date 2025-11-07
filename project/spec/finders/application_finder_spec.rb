# spec/finders/application_finder_spec.rb
require "rails_helper"

RSpec.describe ApplicationFinder, type: :model do
  # A finder that uses a Symbol for the `if` condition
  class SymbolIfFinder < ApplicationFinder
    model ShortUrl

    attribute :apply_filter

    rule :only_first, if: :apply_filter?

    def apply_filter?
      apply_filter
    end

    def only_first
      model.order(:id).limit(1)
    end
  end

  # A finder that has NO `if:` option (always runs rule)
  class NoConditionFinder < ApplicationFinder
    model ShortUrl

    rule :all_records

    def all_records
      model.where("1 = 1")
    end
  end

  let!(:short_url1) do
    ShortUrl.create!(original_url: "https://example.com/1", code: "AA111111")
  end

  let!(:short_url2) do
    ShortUrl.create!(original_url: "https://example.com/2", code: "BB222222")
  end

  describe ".model" do
    it "sets the class-level model to an ActiveRecord::Relation" do
      expect(SymbolIfFinder.model).to be_a(ActiveRecord::Relation)
      expect(SymbolIfFinder.model.klass).to eq(ShortUrl)
    end
  end

  describe ".call" do
    it "creates an instance, yields it, and returns the #call result" do
      yielded_instance = nil

      result = SymbolIfFinder.call(apply_filter: true) do |instance|
        yielded_instance = instance
      end

      expect(yielded_instance).to be_a(SymbolIfFinder)
      expect(result).to match_array([short_url1]) # only_first => first record
    end
  end

  describe "#call / run_rule / if_condition" do
    context "when rule has :if with Symbol and condition is true" do
      it "applies the rule (Symbol branch of if_condition)" do
        result = SymbolIfFinder.call(apply_filter: true)

        # only_first should have limited to the first record
        expect(result).to match_array([short_url1])
      end
    end

    context "when rule has :if with Symbol and condition is false" do
      it "skips the rule and returns original model relation" do
        result = SymbolIfFinder.call(apply_filter: false)

        # When condition is false, run_rule returns `model` unchanged (ShortUrl.all)
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to match_array([short_url1, short_url2])
      end
    end

    context "when rule has NO :if option" do
      it "always runs the rule (else branch of run_rule)" do
        result = NoConditionFinder.call

        # all_records just returns a where("1=1") on model, so same set
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to match_array([short_url1, short_url2])
      end
    end
  end
end
