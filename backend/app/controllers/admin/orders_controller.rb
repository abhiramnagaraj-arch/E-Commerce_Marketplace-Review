module Admin
  class OrdersController < BaseController
    before_action :set_order, only: :show

    def index
      @orders = Order.order(created_at: :desc)
    end

    def show
      @seller_orders = @order.seller_orders.includes(:seller, :order_items)
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end
  end
end
