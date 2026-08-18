class ProductsController < ApplicationController
  before_action :set_product, only: :show

  def index
    @categories = Category.order(:name)
    @category = Category.find(params[:category_id]) if params[:category_id].present?

    products = Product.available.includes(:category)
    products = products.where(category: @category) if @category
    products = products.order(created_at: :desc)

    @products, @page, @total_pages, = paginate(products, per_page: 8)

    load_product_offers(@products, category: @category)
  end

  def show
    @product_offers = Promotion.live.for_product(@product)
  end

  private

  def set_product
    @product = Product.available.includes(:category, :seller).find(params[:id])
  end
end