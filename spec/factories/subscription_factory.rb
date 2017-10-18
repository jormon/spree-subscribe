FactoryGirl.define do
  factory :subscription, :class => Spree::Subscription do
    times 3
    time_unit 3  # DD: 3 = months

    trait :with_line_item do
      transient do
        line_item nil
      end
      # bind the line item to the subscription
      after :create do |subscription, evaluator|
        evaluator.with_line_item.subscription = subscription
        evaluator.with_line_item.save!
      end
    end

    trait :activated do
      association :order, factory: :order_ready_to_ship

      after :create do |subscription|
        # need to link the line items to the subscription
        line_items = subscription.order.line_items
        line_items.update_all(subscription_id: subscription.id)
        # need to copy the information out of the order
        subscription.start
      end
    end
  end
end
