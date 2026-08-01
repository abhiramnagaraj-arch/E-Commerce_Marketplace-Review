class Promotion < ApplicationRecord
  enum :kind, {
    coupon: 0,
    product_discount: 1,
    category_discount: 2,
    sale: 3
  }

  belongs_to :product, optional: true
  belongs_to :category, optional: true

  before_validation :prepare_fields

  validates :name, presence: true
  validates :discount_percent,numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
  validates :min_order_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :code, presence: true, if: :coupon?
  validates :code, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :product, presence: true, if: :product_discount?
  validates :category, presence: true, if: :category_discount?
  validates :starts_at, :ends_at, presence: true, if: :sale?
  validate :valid_dates

  def self.best_for(items, code: nil)
    if code.present?
      promotion = find_by("LOWER(code) = ?", code.downcase)
      return promotion if promotion&.coupon? && promotion.discount_total(items).positive?
    
      return nil
    end

    promotion = where(active: true).where.not(kind: kinds[:coupon]).select(&:available_now?).max_by do |offer|
      offer.discount_total(items)
    end

    promotion if promotion&.discount_total(items)&.positive?
  end

  def discounts_for(items)
    return {} unless eligible?(items)

    items.to_h do |item|
      discount = applies_to?(item) ? percentage_of(item.total_price) : 0.to_d
      [ item.id, discount ]
    end
  end

  def discount_total(items)
    discounts_for(items).values.sum
  end

  def eligible?(items)
    return false unless available_now?

    items.sum(&:total_price) >= min_order_amount
  end

  def available_now?
    return false unless active?
    return false if starts_at.present? && starts_at > Time.current
    return false if ends_at.present? && ends_at < Time.current

    true
  end

  def toggle_status
    update(active: !active)
  end

  private

  def applies_to?(item)
    return true if coupon? || sale?
    return item.product_id == product_id if product_discount?
    return item.product.category_id == category_id if category_discount?

    false
  end

  def percentage_of(amount)
    (amount * discount_percent / 100).round(2)
  end

  def prepare_fields
    self.code = coupon? ? code.to_s.strip.upcase.presence : nil
    self.product = nil unless product_discount?
    self.category = nil unless category_discount?
  end

  def valid_dates
    return unless starts_at && ends_at
    return if ends_at > starts_at

    errors.add(:ends_at, "must be after the start date")
  end
end