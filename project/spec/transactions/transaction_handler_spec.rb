require 'rails_helper'

RSpec.describe Transaction::Handler do
  # Define a dummy class to include the Transaction::Handler module
  class DummyTransactionClass
    include Transaction::Handler

    def successful_transaction
      transaction(-> { true })
    end

    def failing_transaction
      transaction(-> { raise StandardError, "Transaction failure" })
    end
  end

  let(:dummy_instance) { DummyTransactionClass.new }

  describe "#transaction" do
    context "when transaction is successful" do
      it "returns the expected result" do
        expect(dummy_instance.successful_transaction).to eq(true)
      end
    end

    context "when transaction fails" do
      it "logs the error and re-raises the exception" do
        expect(Rails.logger).to receive(:error).with("Transaction failed: Transaction failure")

        expect { dummy_instance.failing_transaction }.to raise_error(StandardError, "Transaction failure")
      end
    end
  end
end
