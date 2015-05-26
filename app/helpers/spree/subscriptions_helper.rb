module Spree::SubscriptionsHelper
  def subscription_price(subscription)
    subscription.line_item.display_amount
  end
end
