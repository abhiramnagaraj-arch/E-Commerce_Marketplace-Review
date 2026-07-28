class Coupon < ApplicationRecord
  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :discount_percent, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
  validates :min_order_amount, numericality: { greater_than_or_equal_to: 0 }

  def valid_for_order?(amount)
    active? && amount >= min_order_amount
  end

  def calculate_discount(amount)
    return 0.0 unless valid_for_order?(amount)
    (amount * discount_percent / 100.0).round(2)
  end
end
