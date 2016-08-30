require "spec_helper"

describe Spree::Order do
  describe "prune_subscriptions" do
    it "it removes un-referenced subscriptions"
    it "keeps referenced subscriptions"
  end

  describe "#subscription?" do
    before :each do
      allow(subject).to receive(:subscription_id).and_return nil
      allow(subject).to receive(:subscriptions).and_return []
    end
    it "returns false" do
      expect(subject).to_not be_subscription
    end

    it "returns true if an order is a recurrance of a subscription" do
      allow(subject).to receive(:subscription_id).and_return 123
      expect(subject).to be_subscription
    end

    it "returns true if an order originates subscriptions" do
      subscription = double "subscription"
      allow(subject).to receive(:subscriptions).and_return [subscription]
      expect(subject).to be_subscription
    end
  end
end
