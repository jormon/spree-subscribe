require 'spec_helper'

describe Spree::Subscription do
  context "validation" do
    it "cannot make multiple subscriptions per orderXinterval"
    it "has many line items"
  end


  context "that is in 'cart' state" do
    subject { create :subscription }

    it "is in the 'cart' state" do
      subject.state.should eq("cart")
    end

    it "should have no reorder date" do
      subject.reorder_on.should be_nil
    end

  end

  context "once activiated" do
    subject { create :subscription, :activated }

    it "should have a billing address" do
      subject.billing_address.should be
    end

    it "should have a shipping address" do
      subject.shipping_address.should be
    end

    it "should have a ship method" do
      subject.shipping_method.should be
    end

    it "should have a payment method" do
      subject.payment_method.should be
    end

    it "should have a payment source" do
      subject.source.should be
    end

    it "should have a user" do
      subject.user.should be
    end

    it "should have reorder date that is three months (i.e. subscription"\
      "interval) from today on activation" do
      subject.reorder_on.should eq(Date.today + 3.month)
    end
  end

  context "that is ready for reorder" do
    subject { create :subscription, :activated}

    it "should have reorder_on reset" do
      # force this back to today
      subject.update_attribute(:reorder_on, Date.today)

      subject.reorder_on.should eq(Date.today)
      subject.reorder.should be_true
      subject.reorder_on.should eq(Date.today + 3.month)
    end

    it "should have a valid order" do
      subject.reorder.should be_true
      subject.reorders.count.should eq(1)
    end

    it "should have a valid order with a billing address" do
      subject.create_reorder.should be_true
      order = subject.reorders.first
      order.bill_address.should == subject.billing_address  # DD: uses == operator override in Spree::Address
      order.bill_address.id.should_not eq subject.billing_address.id # DD: not the same database record
    end

    it "should have a valid order with a shipping address" do
      subject.create_reorder.should be_true
      order = subject.reorders.first
      order.ship_address.should == subject.shipping_address  # DD: uses == operator override in Spree::Address
      order.ship_address.id.should_not eq subject.shipping_address.id # DD: not the same database record
    end

    it "should have a valid line item" do
      subject.create_reorder
      order = subject.reorders.first
      order.line_items.count.should eq(1)
    end

    it "should have a valid order with a shipping method" do
      subject.create_reorder
      subject.select_shipping.should be_true

      order = subject.reorders.first
      order.shipments.count.should eq(1)

      s = order.shipments.first
      expect(s.shipping_method.code).to eq subject.shipping_method.code
    end

    it "should have a valid order with a payment method" do
      subject.create_reorder
      subject.select_shipping
      subject.add_payment.should be_true

      order = subject.reorders.first
      order.payments.count.should eq(1)

      payment = order.payments.first
      expect(payment.payment_method).to eq subject.payment_method  # DD: should be same database record
    end

    it "should have a valid order with a payment source" do
      subject.create_reorder
      subject.select_shipping
      subject.add_payment.should be_true

      order = subject.reorders.first
      order.payments.count.should be(1)
      expect(order.payments.first.source).to eq subject.source  # DD: should be same database record
    end

    it "should have a payment" do
      subject.create_reorder
      subject.select_shipping
      subject.add_payment.should be_true

      order = subject.reorders.first
      order.payments.should be
    end

    it "should have a completed order" do
      subject.reorder.should be_true

      order = subject.reorders.first
      order.state.should eq("complete")
      order.completed?.should be
    end
  end
end
