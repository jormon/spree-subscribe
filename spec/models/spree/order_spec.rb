require "spec_helper"

describe Spree::Order do
  describe "#prune_subscriptions" do
    let!(:order) { create :complex_subscription_order }
    let(:subscriptions) { order.subscriptions }
    let(:single_li_subscription) do
      subscriptions.detect { |s| s.line_items.count == 1 }
    end
    let(:double_li_subscription) do
      subscriptions.detect { |s| s.line_items.count == 2 }
    end

    context "removing the single line item" do
      before(:each) { single_li_subscription.line_items.first.destroy }

      it "removes the single subscription" do
        expect(Spree::Subscription.where(id: single_li_subscription.id)).
          to_not be_present
      end
      it "keeps the double subscription" do
        expect(order.subscriptions.reload).to eq [double_li_subscription]
      end
    end

    context "removing one of the double line items" do
      before(:each) { double_li_subscription.line_items.first.destroy }

      it "keeps both subscriptions" do
        expect(order.subscriptions.count).to eq 2
      end
    end
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
