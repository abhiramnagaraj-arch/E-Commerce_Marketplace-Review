class CategoriesController < ApplicationController
  before_action :set_category, only: :show

  def index
    @categories = Category.order(:name)
    @product_counts = Product.available.group(:category_id).count
  end

  def show
    products = @category.products.available.includes(:seller).order(created_at: :desc)
    @products, @page, @total_pages, @product_count = paginate(products, per_page: 8)

    load_offers
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def load_offers
    offers = Promotion.live.includes(:tiers, :seller).for_product_list(@products).to_a
    @sales = offers.select(&:sale?).uniq(&:id)
    @category_offers = offers.select do |offer|
      offer.category_discount? && offer.category_id == @category.id
    end
    @product_offers = offers.select(&:product_discount?).group_by(&:product_id)
  end
end