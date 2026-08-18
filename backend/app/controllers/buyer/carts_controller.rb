module Buyer
  class CartsController < BaseController
    before_action :set_cart

    def show
      load_cart_items
      load_cart_offers
      select_cart_offer

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
        session[:promotion_manually_picked] = true
        redirect_to buyer_cart_path, notice: "#{offer.name} selected."
      else
        redirect_to buyer_cart_path, alert: "This offer is not unlocked yet."
      end
    end

    private

    def load_cart_items
      @all_cart_items = @cart.cart_items.includes(product: :category).to_a
      @cart_items, @items_page, @items_total_pages = paginate(
        @all_cart_items,
        per_page: 5,
        param: :items_page
      )
    end

    def load_cart_offers
      @offers = available_offers(@all_cart_items).map do |offer|
        offer.details(@all_cart_items, current_user)
      end

      unlocked = @offers.select { |info| info[:level] }
      locked = @offers.reject { |info| info[:level] }

      unlocked.sort_by! { |info| -info[:saving] }
      locked.sort_by! do |info|
        used_position = info[:used] ? 1 : 0
        [ used_position, info[:left] ]
      end

      @offers = unlocked + locked
      @best = unlocked.first
      @recommended_id = @best&.dig(:offer)&.id
    end

    def select_cart_offer
      selected = if session[:promotion_manually_picked]
        @offers.find do |info|
          info[:offer].id == session[:promotion_id].to_i && info[:level]
        end
      end

      session.delete(:promotion_manually_picked) unless selected
      selected ||= @best

      @promotion = selected&.fetch(:offer)
      @picked_id = @promotion&.id

      if @promotion
        session[:promotion_id] = @promotion.id
      else
        session.delete(:promotion_id)
      end
    end

    def set_cart
      @cart = current_cart
    end

    def cart_item
      @cart.cart_items.find(params[:id])
    end

    def available_offers(items)
      Promotion.live
        .includes(:tiers)
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