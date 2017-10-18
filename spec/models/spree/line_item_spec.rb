require "spec_helper"

describe Spree::LineItem do
  it "calls prune_subscriptions on its order when destroyed" do
    order = create :order_with_line_items
    line_item = order.line_items.first
    order.should_receive :prune_subscriptions
    line_item.destroy
  end
end
