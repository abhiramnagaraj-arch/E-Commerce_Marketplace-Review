class Product < ApplicationRecord
  belongs_to :category
  belongs_to :seller, class_name: "User", inverse_of: :products

  has_many :order_items, dependent: :restrict_with_error
  has_many :promotions, dependent: :restrict_with_error

  scope :available, -> { where(active: true) }

  validates :title, :brand, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def archive
    update(active: false)
  end
end