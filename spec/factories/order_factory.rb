FactoryGirl.define do
  # an order with two monthly line items, and one weekly one.
  factory :complex_subscription_order, parent: :order_with_line_items do
    transient do
      line_items_count 3
    end

    after :create do |order|
      order.line_items.each_slice(2).each_with_index do |lis, index|
        subscription = create :subscription, times: (index + 1), order: order
        lis.each do |li|
          li.update_attribute(:subscription_id, subscription.id)
        end
      end
    end
  end
end
