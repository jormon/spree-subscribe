module Spree::SubscriptionsHelper
  def subscription_price(subscription)
    Spree::Money.new(subscription.line_items.map(&:amount).sum).to_html
  end

  def subscription_price_difference_for(variant:)
    Spree::Money.new variant.price - variant.subscribed_price
  end

  def subscription_price_difference_for_line_item(line_item)
    difference = subscription_price_difference_for \
      variant: line_item.variant
    Spree::Money.new(difference.money.to_f * line_item.quantity)
  end
end
