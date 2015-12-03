class Spree::SubscriptionAbility
  include CanCan::Ability

  def initialize(user)
    can :manage, Spree::Subscription do |sub|
      sub.user == user
    end

    can :create, Spree::Subscription do |sub|
      sub.id.present?
    end

    if user.respond_to?(:has_spree_role?) && user.has_spree_role?('admin')
      can :admin, Spree::Subscription
    else
      cannot :admin, Spree::Subscription
    end
  end
end
