module Seller
  class DashboardController < BaseController
    def show
      @products = current_user.products.order(created_at: :desc)
      @seller_orders = current_user.seller_orders.order(created_at: :desc).limit(5)
    end
  end
end