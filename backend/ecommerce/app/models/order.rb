class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  validates :customer_name, :customer_email, :customer_address, presence: true
  validates :total_amount, :final_amount, numericality: { greater_than_or_equal_to: 0 }
end
