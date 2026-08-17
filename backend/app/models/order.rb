class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy
  has_many :seller_orders, dependent: :destroy
  belongs_to :buyer, class_name: "User", inverse_of: :orders
  belongs_to :promotion, optional: true

  validates :customer_name, :customer_email, :customer_address, presence: true
  validates :total_amount, :discount_amount, :final_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :promotion_id,
    uniqueness: { scope: :buyer_id, message: "coupon has already been used" },
    if: -> { promotion&.coupon? }

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
      self.promotion = applied_promotion

      if save
        create_order_items(items, summary[:line_discounts])
        cart.destroy!
        placed = true
      else
        raise ActiveRecord::Rollback
      end
    end

    placed
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
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
      items = order_items.order(:id).reject do |item|
        item.rejected? || item.canceled?
      end

      if items.empty? || items.any? { |item| !item.may_cancel? }
        errors.add(:base, "This order can no longer be canceled because an item has shipped.")
        raise ActiveRecord::Rollback
      end

      items.each do |item|
        unless item.cancel_by_buyer(reason)
          errors.add(:base, item.errors.full_messages.to_sentence)
          raise ActiveRecord::Rollback
        end
      end

      update!(status: "canceled", cancel_reason: reason, canceled_at: Time.current)
      canceled = true
    end

    canceled
  end

  def may_cancel_order?
    items = order_items.reject { |item| item.rejected? || item.canceled? }
    items.any? && items.all?(&:may_cancel?)
  end

  def refresh_status
    with_lock do
      items = order_items.reload.to_a
      active_items = items.reject do |item|
        item.rejected? || item.canceled?
      end

      new_status =
        if active_items.empty?
          "canceled"
        elsif active_items.all?(&:delivered?)
          "delivered"
        elsif active_items.any?(&:delivered?)
          "partially_delivered"
        elsif active_items.all? { |item| item.shipped? || item.delivered? }
          "shipped"
        elsif active_items.any? { |item| item.processing? || item.shipped? }
          "processing"
        else
          "confirmed"
        end

      update!(
        status: new_status,
        total_amount: active_items.sum(&:subtotal),
        discount_amount: active_items.sum(&:discount_amount),
        final_amount: active_items.sum(&:final_amount)
      )
    end
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
