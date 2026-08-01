class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :product_id, uniqueness: { scope: :cart_id }
  validate :quantity_within_stock
  validate :product_available

  def total_price
    product.price * quantity
  end

  def increase_quantity
    update(quantity: quantity + 1)
  end

  def decrease_quantity
    quantity == 1 ? destroy : update(quantity: quantity - 1)
  end

  private

  def quantity_within_stock
    return unless product && quantity.to_i > product.stock
    errors.add(:quantity, "exceeds available stock")
  end

  def product_available
    errors.add(:product, "is not available") if product && !product.active?
  end
end