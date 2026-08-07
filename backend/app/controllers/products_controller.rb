class ProductsController < ApplicationController
  before_action :set_product, only: :show

  def index
    if params[:category_id].present?
      @category = Category.find(params[:category_id])
      products = @category.products.available.includes(:category, :seller).order(created_at: :desc)
    else
      products = Product.available.includes(:category, :seller).order(created_at: :desc)
    end
    @products, @page, @total_pages, @product_count = paginate(products, per_page: 8)
    @categories = Category.order(:name)
    offers = Promotion.live.includes(:tiers, :seller).for_product_list(@products).to_a
    @sales = offers.select(&:sale?).uniq(&:id)
    @category_offers = offers.select do |offer|
      @category && offer.category_discount? && offer.category_id == @category.id
    end
    @product_offers = offers.select(&:product_discount?).group_by(&:product_id)
  end

  def show
    @product_offers = Promotion.live.includes(:tiers, :seller).for_product(@product)
  end

  private

  def set_product
    @product = Product.available.includes(:category, :seller).find(params[:id])
  end
end
