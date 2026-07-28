class CartsController < ApplicationController
  def show
    @cart = current_cart
    @coupon = current_coupon
  end

  def add_item
    product = Product.find(params[:product_id])
    cart_item = current_cart.add_product(product)
    if cart_item.save
      redirect_to cart_path, notice: "#{product.title} was added to your cart."
    else
      redirect_to products_path, alert: "Could not add product to cart."
    end
  end

  def remove_item
    cart_item = current_cart.cart_items.find(params[:id])
    cart_item.destroy
    redirect_to cart_path, notice: "Item removed from cart."
  end

  def update_quantity
    cart_item = current_cart.cart_items.find(params[:id])
    quantity = params[:quantity].to_i
    if quantity > 0
      cart_item.update(quantity: quantity)
      redirect_to cart_path, notice: "Cart updated."
    else
      cart_item.destroy
      redirect_to cart_path, notice: "Item removed from cart."
    end
  end

  def apply_coupon
    code = params[:coupon_code]&.strip
    coupon = Coupon.find_by("LOWER(code) = ?", code.to_s.downcase)
    if coupon && coupon.active?
      if coupon.valid_for_order?(current_cart.total_price)
        session[:coupon_code] = coupon.code
        redirect_to cart_path, notice: "Coupon '#{coupon.code}' applied successfully!"
      else
        redirect_to cart_path, alert: "Minimum order amount of ₹#{coupon.min_order_amount} required for this coupon."
      end
    else
      redirect_to cart_path, alert: "Invalid or inactive coupon code."
    end
  end

  def remove_coupon
    session[:coupon_code] = nil
    redirect_to cart_path, notice: "Coupon removed."
  end
end
