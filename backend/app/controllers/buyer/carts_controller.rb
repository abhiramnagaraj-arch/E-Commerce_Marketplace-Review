module Buyer
  class CartsController < BaseController
    before_action :set_cart

    def show
      @all_cart_items = @cart.cart_items.includes(product: :category).to_a
      @cart_items, @items_page, @items_total_pages = paginate(@all_cart_items, per_page: 5, param: :items_page)
      @offers = available_offers(@all_cart_items).map do |offer|
        offer.details(@all_cart_items, current_user)
      end
      @best = @offers.select { |info| info[:level] }.max_by { |info| info[:saving] }
      @offers.sort_by! do |info|
        [ info[:level] ? 0 : 1, info[:used] ? 1 : 0, info[:level] ? -info[:saving] : info[:left] ]
      end
      selected = @offers.find do |info|
        info[:offer].id == session[:promotion_id].to_i && info[:level]
      end
      selected ||= @best
      @promotion = selected&.fetch(:offer)
      @picked_id = @promotion&.id
      @promotion ? session[:promotion_id] = @promotion.id : session.delete(:promotion_id)
      @summary = @cart.summary(@promotion, items: @all_cart_items)
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

    def pick_offer
      items = @cart.cart_items.includes(product: :category).to_a
      offer = available_offers(items).find_by(id: params[:promotion_id])

      if offer&.fits?(items, current_user)
        session[:promotion_id] = offer.id
        redirect_to buyer_cart_path, notice: "#{offer.name} selected."
      else
        redirect_to buyer_cart_path, alert: "This offer is not unlocked yet."
      end
    end

    private

    def set_cart
      @cart = current_cart
    end

    def cart_item
      @cart.cart_items.find(params[:id])
    end

    def available_offers(items)
      Promotion.live
        .includes(:tiers, :product, :category, :seller)
        .for_cart(
          items.map(&:product_id),
          items.map { |item| item.product.category_id }.uniq,
          items.map { |item| item.product.seller_id }.uniq
        )
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
