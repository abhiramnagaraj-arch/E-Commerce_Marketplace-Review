class Category < ApplicationRecord
  has_many :products, dependent: :restrict_with_error
  has_many :promotions, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end