class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  belongs_to :buyer, class_name: "User", inverse_of: :cart

  def add_product(product)
    current_item = cart_items.find_by(product_id: product.id)
    if current_item
      current_item.quantity += 1
    else
      current_item = cart_items.build(product_id: product.id, quantity: 1)
    end
    current_item
  end

  def summary(promotion = nil, items: nil)
    items = items || cart_items.includes(:product).to_a
    subtotal = items.sum(&:total_price)
    line_discounts = promotion ? promotion.discounts(items) : {}
    discount = line_discounts.values.sum

    {
      item_count: items.sum(&:quantity),
      subtotal: subtotal,
      discount: discount,
      total: subtotal - discount,
      promotion: discount.positive? ? promotion : nil,
      line_discounts: line_discounts
    }
  end
end