class SellerOrder < ApplicationRecord
  belongs_to :order
  belongs_to :seller, class_name: "User", inverse_of: :seller_orders
  has_many :order_items, dependent: :restrict_with_error

  enum :status, {
    confirmed: "confirmed",
    processing: "processing",
    shipped: "shipped",
    partially_delivered: "partially_delivered",
    delivered: "delivered",
    rejected: "rejected",
    canceled: "canceled"
  }

  def refresh_status
    items = order_items.reload.to_a
    active_items = items.reject { |item| item.rejected? || item.canceled? }

    new_status =
      if items.all?(&:rejected?)
        "rejected"
      elsif items.all?(&:canceled?) || active_items.empty?
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

    update!(status: new_status)
    order.refresh_status
  end

  def seller_total
    active_order_items.sum(:subtotal)
  end

  def promotion_total
    active_order_items.sum(:discount_amount)
  end

  private

  def active_order_items
    order_items.where.not(status: %w[rejected canceled])
  end
end