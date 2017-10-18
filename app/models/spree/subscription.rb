require 'concerns/intervalable'

class Spree::Subscription < Spree::Base
  include Intervalable

  # this is the order object that *created* the subscription
  belongs_to :order, :class_name => "Spree::Order"

  # these are the order objects a subscription has spawned
  has_many :reorders, :class_name => "Spree::Order"

  # all of the items in the re-order
  has_many :line_items, :class_name => "Spree::LineItem"

  belongs_to :billing_address, :foreign_key => :billing_address_id, :class_name => "Spree::Address"
  belongs_to :shipping_address, :foreign_key => :shipping_address_id, :class_name => "Spree::Address"
  belongs_to :shipping_method
  belongs_to :source, :polymorphic => true, :validate => true
  belongs_to :payment_method
  belongs_to :user, :class_name => Spree.user_class.to_s

  scope :cart, -> { where(state: 'cart') }
  scope :active, -> { where(state: 'active') }
  scope :cancelled, -> { where(state: 'cancelled') }
  scope :current, -> { where(state: ['active', 'inactive']) }
  scope :due, -> { active.where("reorder_on <= ?", Date.today) }

  attr_accessor :new_order

  state_machine :state, :initial => 'cart' do
    event :suspend do
      transition :to => 'inactive', :from => 'active'
    end
    event :start, :resume do
      transition :to => 'active', :from => ['cart','inactive']
    end
    event :cancel do
      transition :to => 'cancelled', :from => 'active'
    end

    after_transition :on => :start, :do => :copy_order_information
    after_transition :on => :resume, :do => :check_reorder_date
  end

  def self.reorder_due!
    due.each do |subscription|
      begin
        subscription.reorder
      rescue ActiveRecord::RecordInvalid => ex
        Rails.logger.error \
          "[SUBSCRIPTIONS] could not process subscription #{subscription.id}"
        Airbrake.notify ex, subscription_id: subscription.id
      end
    end
  end

  # DD: TODO pull out into a ReorderBuilding someday
  def reorder
    raise false unless active?

    result = create_reorder and
        select_shipping and
        add_payment and
        confirm_reorder and
        complete_reorder and
        calculate_reorder_date!

    msg =  result ? " -> Next reorder date: #{self.reorder_on}" : " -> FAILED"
    Rails.logger.warn msg
    result
  end

  def create_reorder
    Rails.logger.info "[SPREE::SUBSCRIPTION] Reordering subscription: #{id}"
    Rails.logger.info " -> creating order..."

    self.new_order = Spree::Order.create(
        bill_address: self.billing_address.clone,
        ship_address: self.shipping_address.clone,
        subscription_id: self.id,
        email: self.user.email,
        user_id: self.user_id
    )

    add_subscribed_line_items

    if self.new_order.respond_to?(:store_id)
      self.new_order.store_id = self.line_items.first.order.store_id
    end

    # -> address -> delivery
    progress and progress
  end

  def add_subscribed_line_items
    self.line_items.each do |line_item|
      add_subscribed_line_item line_item
    end
  end

  def add_subscribed_line_item(line_item_master)
    variant = Spree::Variant.find(line_item_master.variant_id)

    line_item = self.new_order.contents.add(variant, line_item_master.quantity)
    line_item.price = line_item_master.price
    line_item.save!
  end

  def select_shipping
    # DD: shipments are created when order state goes to "delivery"
    Rails.logger.info " -> selecting shipping rate..."

    shipment = self.new_order.shipments.first # DD: there should be only one shipment
    rate = shipment.shipping_rates.first{|r| r.shipping_method.id == self.shipping_method.id }
    raise "No rate was found. TODO: Implement logic to select the cheapest rate." unless rate
    shipment.selected_shipping_rate_id = rate.id
    shipment.save
  end

  def add_payment
    Rails.logger.info " -> adding payment..."
    payment = self.new_order.payments.build(amount: self.new_order.outstanding_balance)
    payment.source = self.source
    payment.payment_method = self.payment_method
    payment.save!

    progress # -> payment
  end

  def confirm_reorder
    progress # -> confirm
  end

  def complete_reorder
    self.new_order.update!
    progress && self.new_order.save # -> complete
  end

  def calculate_reorder_date!
    self.reorder_on ||= Date.today
    self.reorder_on += self.time
    save
  end

  # DD: assumes interval attributes come in when created/updated in cart
  def copy_order_information
    # DD: TODO: set quantity?
    calculate_reorder_date!

    # auto create user if nil
    if self.order.user_id.nil?
      user = Spree::User.create! \
        email: self.order.email,
        password: Devise.friendly_token,
        bill_address_id: self.order.bill_address_id,
        ship_address_id: self.order.ship_address_id
      self.order.user_id = user.id
      self.order.save!

      # so self.order.user_id is accurate below
      self.order.reload
    end

    payment = self.order.payments.detect do |payment|
      payment.state == "completed"
    end

    update_attributes(
        :billing_address_id => self.order.bill_address_id,
        :shipping_address_id => self.order.ship_address_id,
        :shipping_method_id => self.order.shipments.first.shipping_method.id,
        :payment_method_id => payment.payment_method_id,
        :source_id => payment.source_id,
        :source_type => payment.source_type,
        :user_id => self.order.user_id
    )
  end

  def self.reorder_states
    @reorder_states ||= state_machine.states.map(&:name) - ["cart"]
  end

  def new_order_state
    self.new_order.state
  end

  def progress
    current_state = new_order_state
    result = self.new_order.next
    success = !!result && current_state != new_order_state
    unless success
      Rails.logger.error " !! Order progression failed. Status still"\
        "'#{new_order_state}'"
      Rails.logger.error "New Order: #{new_order.id}"
      Rails.logger.error "Errors: #{new_order.errors.messages}"
    end
    success
  end
end
