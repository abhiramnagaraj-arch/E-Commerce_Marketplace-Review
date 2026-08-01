module Buyer
  class CartsController < BaseController
    before_action :set_cart

    def show
      @cart_items = @cart.cart_items.includes(:product)
      @promotion = current_promotion(@cart_items)
      @line_totals = @cart_items.to_h { |item| [ item.id, item.total_price ] }
      @summary = @cart.summary(@promotion)
      render "carts/show"
    end

    def add_item
      product = Product.available.find(params[:product_id])
      cart_item = @cart.add_product(product)

      if cart_item.save
        redirect_to buyer_cart_path, notice: "Product was added to your cart."
      else
        redirect_to products_path, alert: cart_item.errors.full_messages.to_sentence
      end
    end

    def remove_item
      cart_item.destroy
      redirect_to buyer_cart_path, notice: "Item removed from cart."
    end

    def increment_item
      if cart_item.increase_quantity
        redirect_to buyer_cart_path, notice: "Cart updated."
      else
        redirect_to buyer_cart_path, alert: cart_item.errors.full_messages.to_sentence
      end
    end

    def decrement_item
      cart_item.decrease_quantity
      redirect_to buyer_cart_path, notice: "Cart updated."
    end

    def apply_promotion
      code = params[:promotion_code].to_s.strip
      items = @cart.cart_items.includes(:product)
      promotion = Promotion.best_for(items, code: code)

      if promotion
        session[:promotion_code] = promotion.code
        redirect_to buyer_cart_path, notice: "#{promotion.name} was applied."
      else
        redirect_to buyer_cart_path, alert: "Promotion code is invalid or does not meet the cart requirements."
      end
    end

    def remove_promotion
      session.delete(:promotion_code)
      redirect_to buyer_cart_path, notice: "Promotion was removed."
    end

    private

    def set_cart
      @cart = current_cart
      authorize! :manage, @cart
    end

    def cart_item
      @cart.cart_items.find(params[:id])
    end
  end
end