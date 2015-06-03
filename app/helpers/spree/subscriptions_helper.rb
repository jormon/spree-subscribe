module Spree::SubscriptionsHelper
  def subscription_price(subscription)
    Spree::Money.new(subscription.line_items.map(&:amount).sum).to_html
  end
end
