module Admin
  class OrdersController < BaseController
    before_action :set_order, only: %i[show cancel]

    def index
      @orders = Order.order(created_at: :desc)
    end

    def show
      @seller_orders = @order.seller_orders.includes(:seller, :order_items)
    end

    def cancel
      if @order.cancel_order(params[:cancel_reason])
        redirect_to admin_order_path(@order), notice: "Order canceled. Product stock has been restored."
      else
        redirect_to admin_order_path(@order), alert: @order.errors.full_messages.to_sentence
      end
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end
  end
end