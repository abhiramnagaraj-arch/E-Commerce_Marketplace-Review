module Seller
  class CategoriesController < BaseController
    before_action :set_category, only: :show

    def index
      @categories = Category.order(:name)
      @product_counts = current_user.products.group(:category_id).count
    end

    def show
      @products = current_user.products.where(category: @category).order(created_at: :desc)
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end
  end
end