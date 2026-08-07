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
      render "orders/new"
    end

    def create
      @order = current_user.orders.build(order_params)

      if @order.place_from_cart(@cart, @promotion)
        session.delete(:promotion_id)
        redirect_to buyer_order_path(@order), notice: "Order placed successfully! Thank you for shopping with us."
      else
        render "orders/new", status: :unprocessable_entity
      end
    end

    def cancel
      if @order.cancel_order(params[:cancel_reason])
        redirect_to buyer_order_path(@order), notice: "Order canceled successfully. Product stock has been restored."
      else
        redirect_to buyer_order_path(@order), alert: @order.errors.full_messages.to_sentence
      end
    end

    private

    def set_cart
      @cart = current_cart
      redirect_to products_path, alert: "Your cart is empty." if @cart.cart_items.empty?
    end

    def set_order
      @order = current_user.orders.find(params[:id])
    end

    def set_summary
      @all_cart_items = @cart.cart_items.includes(:product).to_a
      @cart_items, @items_page, @items_total_pages = paginate(@all_cart_items, per_page: 5, param: :items_page)
      @promotion = current_promotion(@all_cart_items)
      @summary = @cart.summary(@promotion, items: @all_cart_items)
    end

    def order_params
      params.require(:order).permit(:customer_name, :customer_email, :customer_address)
    end
  end
end
