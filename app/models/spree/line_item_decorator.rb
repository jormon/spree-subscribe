Spree::LineItem.class_eval do
  belongs_to :subscription, :dependent => :destroy
end
