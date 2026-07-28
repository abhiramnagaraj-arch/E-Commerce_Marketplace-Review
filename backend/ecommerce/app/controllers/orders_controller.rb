class OrdersController < ApplicationController
  def index
    @orders = Order.order(created_at: :desc)
  end

  def show
    @order = Order.find(params[:id])
  end

  def new
    @cart = current_cart
    if @cart.cart_items.empty?
      redirect_to products_path, alert: "Your cart is empty."
      return
    end
    @order = Order.new
    @coupon = current_coupon
  end

  def create
    @cart = current_cart
    if @cart.cart_items.empty?
      redirect_to products_path, alert: "Your cart is empty."
      return
    end

    @coupon = current_coupon
    total = @cart.total_price
    discount = @coupon ? @coupon.calculate_discount(total) : 0.0
    final = total - discount

    @order = Order.new(order_params)
    @order.total_amount = total
    @order.coupon_code = @coupon&.code
    @order.discount_amount = discount
    @order.final_amount = final
    @order.status = "confirmed"

    if @order.save
      @cart.cart_items.each do |item|
        @order.order_items.create!(
          product: item.product,
          quantity: item.quantity,
          price: item.product.price
        )
      end
      # Clear cart and coupon from session
      @cart.destroy
      session[:cart_id] = nil
      session[:coupon_code] = nil

      redirect_to @order, notice: "Order placed successfully! Thank you for shopping with us."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def order_params
    params.require(:order).permit(:customer_name, :customer_email, :customer_address)
  end
end
