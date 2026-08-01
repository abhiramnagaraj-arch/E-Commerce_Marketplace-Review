module Admin
  class DashboardController < BaseController
    def show
      @category_count = Category.count
      @product_count = Product.available.count
      @order_count = Order.count
      @promotion_count = Promotion.where(active: true).count
    end
  end
end