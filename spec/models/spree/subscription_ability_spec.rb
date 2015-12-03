require "spec_helper"

RSpec.describe Spree::SubscriptionAbility, type: :model do
  let(:user) { create :user }
  let(:ability) { Spree::Ability.new user }

  before :each do
    Spree::Ability.register_ability Spree::SubscriptionAbility
  end

  it "does not let any user admin" do
    expect(ability).to_not be_able_to :admin, Spree::Subscription
  end

  it "lets admins admin" do
    user.spree_roles << Spree::Role.find_or_create_by(name: "admin")
    expect(ability).to be_able_to :admin, Spree::Subscription
  end
end
