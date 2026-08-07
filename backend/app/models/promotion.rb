class Promotion < ApplicationRecord
  enum :kind, {
    coupon: 0,
    product_discount: 1,
    category_discount: 2,
    sale: 3
  }

  belongs_to :product, optional: true
  belongs_to :category, optional: true
  belongs_to :seller, class_name: "User", optional: true
  has_many :tiers,
    -> { order(:minimum_value) },
    class_name: "PromotionTier",
    dependent: :destroy
  has_many :orders, dependent: :restrict_with_error

  accepts_nested_attributes_for :tiers, allow_destroy: true, reject_if: :all_blank

  scope :live, lambda {
    where(active: true)
      .where("starts_at IS NULL OR starts_at <= ?", Time.current)
      .where("ends_at IS NULL OR ends_at >= ?", Time.current)
  }

  scope :for_cart, lambda { |product_ids, category_ids, seller_ids|
    where(kind: :coupon)
      .or(where(kind: :product_discount, product_id: product_ids))
      .or(where(kind: :category_discount, category_id: category_ids))
      .or(where(kind: :sale, seller_id: seller_ids))
  }

  scope :for_product, lambda { |product|
    where(kind: :product_discount, product_id: product.id)
      .or(where(kind: :category_discount, category_id: product.category_id))
      .or(where(kind: :sale, seller_id: product.seller_id))
  }

  scope :for_product_list, lambda { |products|
    product_ids = products.map(&:id)
    category_ids = products.map(&:category_id).uniq
    seller_ids = products.map(&:seller_id).uniq

    where(kind: :product_discount, product_id: product_ids)
      .or(where(kind: :category_discount, category_id: category_ids))
      .or(where(kind: :sale, seller_id: seller_ids))
  }

  before_validation :clean_fields

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { case_sensitive: false }, if: :coupon?
  validates :product, presence: true, if: :product_discount?
  validates :category, presence: true, if: :category_discount?
  validates :seller, presence: true, if: :sale?
  validates :starts_at, :ends_at, presence: true, if: :sale?

  validate :valid_dates
  validate :valid_tiers

  def value(items)
    rows = items_for(items)
    product_discount? ? rows.sum(&:quantity) : rows.sum(&:total_price)
  end

  def level(items)
    total = value(items)
    tiers.select { |tier| tier.minimum_value <= total }.max_by(&:minimum_value)
  end

  def next_level(items)
    total = value(items)
    tiers.find { |tier| tier.minimum_value > total }
  end

  def used_by?(buyer)
    coupon? && buyer.present? && buyer.orders.exists?(promotion_id: id)
  end

  def fits?(items, buyer = nil)
    level(items).present? && !used_by?(buyer)
  end

  def discounts(items)
    current = level(items)
    return {} unless current

    items_for(items).to_h do |item|
      amount = item.total_price * current.discount_percent / 100
      [ item.id, amount.round(2) ]
    end
  end

  def details(items, buyer = nil)
    used = used_by?(buyer)
    current = used ? nil : level(items)
    next_one = used ? nil : next_level(items)

    {
      offer: self,
      level: current,
      next: next_one,
      saving: current ? discounts(items).values.sum : 0.to_d,
      left: next_one ? next_one.minimum_value - value(items) : 0,
      used: used
    }
  end

  def toggle_status
    update(active: !active)
  end

  private

  def items_for(items)
    return items.select { |item| item.product_id == product_id } if product_discount?
    return items.select { |item| item.product.category_id == category_id } if category_discount?
    return items.select { |item| item.product.seller_id == seller_id } if sale?

    items
  end

  def clean_fields
    self.code = coupon? ? code.to_s.strip.upcase.presence : nil
    self.product = nil unless product_discount?
    self.category = nil unless category_discount?
    self.seller = nil unless sale?
  end

  def valid_dates
    return unless starts_at && ends_at
    errors.add(:ends_at, "must be after the start date") if ends_at <= starts_at
  end

  def valid_tiers
    rows = tiers.reject(&:marked_for_destruction?).sort_by { |tier| tier.minimum_value || -1 }
    errors.add(:tiers, "must have at least one level") if rows.empty?
    errors.add(:tiers, "cannot repeat a minimum value") if rows.map(&:minimum_value).uniq.size != rows.size

    repeated = rows.each_cons(2).any? do |first, second|
      second.discount_percent.to_i <= first.discount_percent.to_i
    end
    errors.add(:tiers, "must increase the discount at every level") if repeated
  end
end
