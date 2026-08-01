module Seller
  class OrdersController < BaseController
    before_action :set_seller_order, only: %i[show process_order ship deliver reject]

    def index
      @seller_orders = current_user.seller_orders.includes(:order, :order_items).order(created_at: :desc)
    end

    def show
      @order = @seller_order.order
      @order_items = @seller_order.order_items
    end

    def process_order
      if @seller_order.process!
        redirect_to seller_order_path(@seller_order), notice: "Order is now processing."
      else
        redirect_with_error("Order cannot be processed.")
      end
    end

    def ship
      if @seller_order.ship!
        redirect_to seller_order_path(@seller_order), notice: "Order was marked as shipped."
      else
        redirect_with_error("Order cannot be shipped.")
      end
    end

    def deliver
      if @seller_order.deliver!
        redirect_to seller_order_path(@seller_order), notice: "Order was marked as delivered."
      else
        redirect_with_error("Order cannot be delivered.")
      end
    end

    def reject
      if @seller_order.reject_order(params[:rejection_reason])
        redirect_to seller_order_path(@seller_order),
                    notice: "Order was rejected and stock was restored."
      else
        redirect_with_error(@seller_order.errors.full_messages.to_sentence)
      end
    end

    private

    def set_seller_order
      @seller_order = current_user.seller_orders.find(params[:id])
      authorize! :manage, @seller_order
    end

    def redirect_with_error(message)
      redirect_to seller_order_path(@seller_order), alert: message
    end
  end
end