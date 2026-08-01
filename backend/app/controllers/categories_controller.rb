class CategoriesController < ApplicationController
  before_action :set_category, only: :show

  def index
    @categories = Category.order(:name)
    @product_counts = Product.available.group(:category_id).count
  end

  def show
    @products = @category.products.available.includes(:seller).order(created_at: :desc)
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end
end