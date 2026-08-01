module Buyer
  class CartsController < BaseController
    before_action :set_cart

    def show
      @cart_items = @cart.cart_items.includes(:product)
      @promotion = current_promotion(@cart_items)
      @summary = @cart.summary(@promotion)
      render "carts/show"
    end

    def add_item
      @product = Product.available.find(params[:product_id])
      @cart_item = @cart.add_product(@product)

      if @cart_item.save
        respond_with_cart_update("Product was added to your cart.")
      else
        respond_with_cart_update(@cart_item.errors.full_messages.to_sentence, alert: true)
      end
    end

    def remove_item
      cart_item.destroy
      redirect_back fallback_location: products_path, notice: "Item removed from cart."
    end

    def increment_item
      @cart_item = cart_item
      @product = @cart_item.product

      if @cart_item.increase_quantity
        respond_with_cart_update("Cart updated.")
      else
        respond_with_cart_update(@cart_item.errors.full_messages.to_sentence, alert: true)
      end
    end

    def decrement_item
      @cart_item = cart_item
      @product = @cart_item.product
      @cart_item.decrease_quantity
      @cart_item = nil unless @cart_item.persisted?
      respond_with_cart_update("Cart updated.")
    end

    def apply_promotion
      code = params[:promotion_code].to_s.strip
      items = @cart.cart_items.includes(:product)
      promotion = Promotion.best_for(items, code: code)

      if promotion
        session[:promotion_code] = promotion.code
        redirect_back fallback_location: products_path, notice: "#{promotion.name} was applied."
      else
        redirect_back fallback_location: products_path, alert: "Promotion code is invalid or does not meet the cart requirements."
      end
    end

    def remove_promotion
      session.delete(:promotion_code)
      redirect_back fallback_location: products_path, notice: "Promotion was removed."
    end

    private

    def set_cart
      @cart = current_cart
    end

    def cart_item
      @cart.cart_items.find(params[:id])
    end

    def respond_with_cart_update(message, alert: false)
      respond_to do |format|
        format.turbo_stream do
          alert ? flash.now[:alert] = message : flash.now[:notice] = message
          render :update_item, status: alert ? :unprocessable_entity : :ok
        end
        format.html do
          redirect_back(
            fallback_location: products_path,
            **(alert ? { alert: message } : { notice: message })
          )
        end
      end
    end
  end
end