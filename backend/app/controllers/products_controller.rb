class ProductsController < ApplicationController
  before_action :set_product, only: :show

  def index
    @categories = Category.order(:name)
    @category = Category.find(params[:category_id]) if params[:category_id].present?

    products = Product.available.includes(:category, :seller)
    products = products.where(category: @category) if @category
    products = products.order(created_at: :desc)

    @products, @page, @total_pages, @product_count = paginate(products, per_page: 8)

    load_offers
  end

  def show
    @product_offers = Promotion.live.includes(:tiers, :seller).for_product(@product)
  end

  private

  def set_product
    @product = Product.available.includes(:category, :seller).find(params[:id])
  end

  def load_offers
    offers = Promotion.live.includes(:tiers, :seller).for_product_list(@products).to_a
    @sales = offers.select(&:sale?).uniq(&:id)
    @category_offers = offers.select do |offer|
      @category && offer.category_discount? && offer.category_id == @category.id
    end
    @product_offers = offers.select(&:product_discount?).group_by(&:product_id)
  end
end
