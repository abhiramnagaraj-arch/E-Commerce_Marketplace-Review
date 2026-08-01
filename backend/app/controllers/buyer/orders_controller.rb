module Buyer
  class OrdersController < BaseController
    before_action :set_order, only: %i[show cancel]
    before_action :set_cart, only: %i[new create]
    before_action :set_summary, only: %i[new create]

    def index
      @orders = current_user.orders.includes(:order_items).order(created_at: :desc)
      render "orders/index"
    end

    def show
      @seller_orders = @order.seller_orders.includes(:seller, :order_items)
      render "orders/show"
    end

    def new
      @order = current_user.orders.build
      authorize! :create, @order
      render "orders/new"
    end

    def create
      @order = current_user.orders.build(order_params)
      authorize! :create, @order

      if @order.place_from_cart(@cart, @promotion)
        session.delete(:promotion_code)
        redirect_to buyer_order_path(@order), notice: "Order placed successfully! Thank you for shopping with us."
      else
        render "orders/new", status: :unprocessable_entity
      end
    end

    def cancel
      if @order.cancel_order(params[:cancel_reason])
        redirect_to buyer_order_path(@order),
                    notice: "Order canceled successfully. Product stock has been restored."
      else
        redirect_to buyer_order_path(@order),
                    alert: @order.errors.full_messages.to_sentence
      end
    end

    private

    def set_cart
      @cart = current_cart
      redirect_to products_path, alert: "Your cart is empty." if @cart.cart_items.empty?
    end

    def set_order
      @order = current_user.orders.find(params[:id])
      authorize! :read, @order
    end

    def set_summary
      @cart_items = @cart.cart_items.includes(:product)
      @promotion = current_promotion(@cart_items)
      @line_totals = @cart_items.to_h { |item| [ item.id, item.total_price ] }
      @summary = @cart.summary(@promotion)
    end

    def order_params
      params.require(:order).permit(:customer_name, :customer_email, :customer_address)
    end
  end
end