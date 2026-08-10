module Seller
  class OrdersController < BaseController
    before_action :set_seller_order, only: %i[show process_item ship_item deliver_item reject_item]
    before_action :set_order_item, only: %i[process_item ship_item deliver_item reject_item]

    def index
      @seller_orders = current_user.seller_orders.includes(:order, :order_items).order(created_at: :desc)
    end

    def show
      @order = @seller_order.order
      @order_items = @seller_order.order_items.order(:id)
    end

    def process_item
      if @order_item.process!
        redirect_with_notice("Item is now processing.")
      else
        redirect_with_error("Item cannot be processed.")
      end
    end

    def ship_item
      if @order_item.ship!
        redirect_with_notice("Item was marked as shipped.")
      else
        redirect_with_error("Item cannot be shipped.")
      end
    end

    def deliver_item
      if @order_item.deliver!
        redirect_with_notice("Item was marked as delivered.")
      else
        redirect_with_error("Item cannot be delivered.")
      end
    end

    def reject_item
      if @order_item.reject_item(params[:rejection_reason])
        redirect_with_notice("Item was rejected and its stock was restored.")
      else
        redirect_with_error(@order_item.errors.full_messages.to_sentence)
      end
    end

    private

    def set_seller_order
      @seller_order = current_user.seller_orders.find(params[:id])
    end

    def set_order_item
      @order_item = @seller_order.order_items.find(params[:item_id])
    end

    def redirect_with_notice(message)
      redirect_to seller_order_path(@seller_order), notice: message
    end

    def redirect_with_error(message)
      redirect_to seller_order_path(@seller_order), alert: message
    end
  end
end
