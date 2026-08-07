class PromotionTier < ApplicationRecord
  belongs_to :promotion

  validates :minimum_value,
    numericality: { greater_than_or_equal_to: 0 },
    uniqueness: { scope: :promotion_id }

  validates :discount_percent,
    numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }

  validate :whole_quantity, if: -> { promotion&.product_discount? }

  private

  def whole_quantity
    return if minimum_value.present? && minimum_value >= 1 && minimum_value.to_i == minimum_value
    errors.add(:minimum_value, "must be a whole quantity greater than 0")
  end
end
