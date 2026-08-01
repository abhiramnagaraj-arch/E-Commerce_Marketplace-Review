class SellerOrder < ApplicationRecord
  include AASM

  belongs_to :order
  belongs_to :seller, class_name: "User", inverse_of: :seller_orders
  has_many :order_items, dependent: :restrict_with_error

  validates :rejection_reason, presence: true, if: :rejected?

  aasm column: :status, whiny_transitions: false do
    state :confirmed, initial: true
    state :processing
    state :shipped
    state :delivered
    state :rejected
    state :canceled

    event :process, after: :refresh_order do
      transitions from: :confirmed, to: :processing
    end

    event :ship, after: :refresh_order do
      transitions from: :processing, to: :shipped
    end

    event :deliver, after: :refresh_order do
      transitions from: :shipped, to: :delivered
    end

    event :reject, after: :close_seller_order do
      transitions from: %i[confirmed processing], to: :rejected
    end

    event :cancel, after: :close_seller_order do
      transitions from: %i[confirmed processing], to: :canceled
    end
  end

  def reject_order(reason)
    if reason.blank?
      errors.add(:rejection_reason, "is required")
      return false
    end

    changed = false

    with_lock do
      if may_reject?
        self.rejection_reason = reason
        self.rejected_at = Time.current
        changed = reject!
      else
        errors.add(:base, "This seller order can no longer be rejected.")
      end
    end

    changed
  end

  def cancel_by_buyer
    changed = false

    with_lock do
      if may_cancel?
        changed = cancel!
      else
        errors.add(:base, "This seller order can no longer be canceled.")
      end
    end

    changed
  end

  def seller_total
    order_items.sum(:subtotal)
  end

  def promotion_total
    order_items.sum(:discount_amount)
  end

  private

  def close_seller_order
    restore_stock
    refresh_order
  end

  def restore_stock
    order_items.includes(:product).each do |item|
      product = item.product

      product.with_lock do
        product.update!(stock: product.stock + item.quantity)
      end
    end
  end

  def refresh_order
    order.refresh_status
  end
end