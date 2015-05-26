module Spree::SubscriptionsHelper
  def subscription_price(subscription)
    subscription.line_items.map(&:display_amount).sum.to_html
  end
end
