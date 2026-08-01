class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy
  has_many :seller_orders, dependent: :destroy
  belongs_to :buyer, class_name: "User", inverse_of: :orders

  validates :customer_name, :customer_email, :customer_address, presence: true
  validates :total_amount, :discount_amount, :final_amount, numericality: { greater_than_or_equal_to: 0 }

  def place_from_cart(cart, promotion = nil)
    placed = false

    self.class.transaction do
      items = cart.cart_items.includes(:product).to_a
      items.each { |item| item.product.lock! }

      invalid_item = items.find do |item|
        !item.product.active? || item.quantity > item.product.stock
      end

      if invalid_item
        errors.add(:base, "#{invalid_item.product.title} is unavailable or has insufficient stock")
        raise ActiveRecord::Rollback
      end

      summary = cart.summary(promotion, items: items)
      applied_promotion = summary[:promotion]

      self.total_amount = summary[:subtotal]
      self.discount_amount = summary[:discount]
      self.final_amount = summary[:total]
      self.promotion_name = applied_promotion&.name
      self.promotion_kind = applied_promotion&.kind
      self.promotion_code = applied_promotion&.code

      if save
        create_order_items(items, summary[:line_discounts])
        cart.destroy!
        placed = true
      else
        raise ActiveRecord::Rollback
      end
    end

    placed
  rescue ActiveRecord::RecordInvalid => error
    errors.add(:base, error.message)
    false
  end

  def cancel_order(reason)
    if reason.blank?
      errors.add(:cancel_reason, "is required")
      return false
    end

    canceled = false

    self.class.transaction do
      lock!
      parts = seller_orders.order(:id).reject do |part|
        part.rejected? || part.canceled?
      end

      if parts.empty? || parts.any? { |part| !part.may_cancel? }
        errors.add(:base, "This order can no longer be canceled because an item has shipped.")
        raise ActiveRecord::Rollback
      end
 
      parts.each do |part|
        unless part.cancel_by_buyer
          errors.add(:base, part.errors.full_messages.to_sentence)
          raise ActiveRecord::Rollback
        end
      end

      update!(status: "canceled", cancel_reason: reason, canceled_at: Time.current)
      canceled = true
    end

    canceled
  end

  def may_cancel_order?
    parts = seller_orders.reject { |part| part.rejected? || part.canceled? }
    parts.any? && parts.all?(&:may_cancel?)
  end

  def refresh_status
    active_parts = seller_orders.reload.reject do |part|
      part.rejected? || part.canceled?
    end

    new_status =
      if active_parts.empty?
        "canceled"
      elsif active_parts.all?(&:delivered?)
        "delivered"
      elsif active_parts.all? { |part| part.shipped? || part.delivered? }
        "shipped"
      elsif active_parts.any? { |part| part.processing? || part.shipped? || part.delivered? }
        "processing"
      else
        "confirmed"
      end

    active_items = order_items.where(seller_order: active_parts)

    update!(
      status: new_status,
      total_amount: active_items.sum(:subtotal),
      discount_amount: active_items.sum(:discount_amount),
      final_amount: active_items.sum(:final_amount)
    )
  end

  private

  def create_order_items(items, line_discounts)
    parts = items.group_by { |item| item.product.seller_id }.to_h do |seller_id, _|
      [ seller_id, seller_orders.create!(seller_id: seller_id) ]
    end

    items.each do |item|
      subtotal = item.total_price
      discount = line_discounts.fetch(item.id, 0.to_d)

      order_items.create!(
        seller_order: parts[item.product.seller_id],
        product: item.product,
        product_title: item.product.title,
        quantity: item.quantity,
        price: item.product.price,
        subtotal: subtotal,
        discount_amount: discount,
        final_amount: subtotal - discount
      )

      item.product.update!(stock: item.product.stock - item.quantity)
    end
  end
end