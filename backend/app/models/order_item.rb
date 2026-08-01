class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :seller_order
  belongs_to :product

  validates :product_title, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :price, :subtotal, :discount_amount, :final_amount, numericality: { greater_than_or_equal_to: 0 }

end