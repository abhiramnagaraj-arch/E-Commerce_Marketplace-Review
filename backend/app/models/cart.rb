class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items
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

  def total_price
    cart_items.includes(:product).sum(&:total_price)
  end

  def summary(promotion = nil, items: nil)
    items ||= cart_items.includes(:product).to_a
    subtotal = items.sum(&:total_price)
    line_discounts = promotion ? promotion.discounts_for(items) : {}
    discount = line_discounts.values.sum

    {
      item_count: items.sum(&:quantity),
      subtotal: subtotal,
      discount: discount,
      discounted: discount.positive?,
      total: subtotal - discount,
      promotion: discount.positive? ? promotion : nil,
      line_discounts: line_discounts
    }
  end
end