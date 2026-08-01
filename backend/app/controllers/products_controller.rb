class ProductsController < ApplicationController
  before_action :set_product, only: :show

  def index
    if params[:category_id].present?
      @category = Category.find(params[:category_id])
      @products = @category.products.available.order(created_at: :desc)
    else
      @products = Product.available.includes(:category).order(created_at: :desc)
    end
    @categories = Category.order(:name)
  end

  def show
  end

  private

  def set_product
    @product = Product.available.find(params[:id])
  end
end