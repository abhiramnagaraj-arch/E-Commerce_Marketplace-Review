class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  enum :role, { buyer: 0, seller: 1, admin: 2 }

  validates :name, presence: true

  has_many :products, foreign_key: :seller_id, inverse_of: :seller, dependent: :restrict_with_error
  has_many :store_sales, class_name: "Promotion", foreign_key: :seller_id, dependent: :restrict_with_error
  has_many :seller_orders, foreign_key: :seller_id, inverse_of: :seller, dependent: :restrict_with_error
  has_one :cart, foreign_key: :buyer_id, inverse_of: :buyer, dependent: :destroy
  has_many :orders, foreign_key: :buyer_id, inverse_of: :buyer, dependent: :restrict_with_error
end