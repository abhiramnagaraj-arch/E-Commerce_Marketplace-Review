class OrderItem < ApplicationRecord
  include AASM

  belongs_to :order
  belongs_to :seller_order
  belongs_to :product

  validates :product_title, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :price, :subtotal, :discount_amount, :final_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :rejection_reason, presence: true, if: :rejected?
  validates :cancel_reason, presence: true, if: :canceled?

  aasm column: :status, whiny_transitions: false do
    state :confirmed, initial: true
    state :processing
    state :shipped
    state :delivered
    state :rejected
    state :canceled

    event :process, after: :refresh_statuses do
      transitions from: :confirmed, to: :processing
    end

    event :ship, after: :refresh_statuses do
      transitions from: :processing, to: :shipped
    end

    event :deliver, after: :refresh_statuses do
      transitions from: :shipped, to: :delivered
    end

    event :reject, after: :close_item do
      transitions from: %i[confirmed processing], to: :rejected
    end

    event :cancel, after: :close_item do
      transitions from: %i[confirmed processing], to: :canceled
    end
  end

  def reject_item(reason)
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
        errors.add(:base, "This item can no longer be rejected.")
      end
    end

    changed
  end

  def cancel_by_buyer(reason)
    if reason.blank?
      errors.add(:cancel_reason, "is required")
      return false
    end

    changed = false

    with_lock do
      if may_cancel?
        self.cancel_reason = reason
        self.canceled_at = Time.current
        changed = cancel!
      else
        errors.add(:base, "This item can no longer be canceled.")
      end
    end

    changed
  end

  private

  def close_item
    restore_stock
    refresh_statuses
  end

  def restore_stock
    product.with_lock do
      product.update!(stock: product.stock + quantity)
    end
  end

  def refresh_statuses
    seller_order.refresh_status
  end
end