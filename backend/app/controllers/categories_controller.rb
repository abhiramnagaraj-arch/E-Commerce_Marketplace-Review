class CategoriesController < ApplicationController
  before_action :set_category, only: :show

  def index
    @categories = Category.order(:name)
    @product_counts = Product.available.group(:category_id).count
  end

  def show
    products = @category.products.available.order(created_at: :desc)
    @products, @page, @total_pages, @product_count = paginate(products, per_page: 8)

    load_product_offers(@products, category: @category)
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end
end
