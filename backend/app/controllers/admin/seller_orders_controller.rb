module Admin
  class SellerOrdersController < BaseController
    before_action :set_seller_order

    def process_order
      if @seller_order.process!
        redirect_to admin_order_path(@seller_order.order), notice: "Seller order is now processing."
      else
        redirect_with_error("Seller order cannot be processed.")
      end
    end

    def ship
      if @seller_order.ship!
        redirect_to admin_order_path(@seller_order.order), notice: "Seller order was marked as shipped."
      else
        redirect_with_error("Seller order cannot be shipped.")
      end
    end

    def deliver
      if @seller_order.deliver!
        redirect_to admin_order_path(@seller_order.order), notice: "Seller order was marked as delivered."
      else
        redirect_with_error("Seller order cannot be delivered.")
      end
    end

    def reject
      if @seller_order.reject_order(params[:rejection_reason])
        redirect_to admin_order_path(@seller_order.order),
                    notice: "Seller order was rejected and stock was restored."
      else
        redirect_with_error(@seller_order.errors.full_messages.to_sentence)
      end
    end

    private

    def set_seller_order
      @seller_order = SellerOrder.find(params[:id])
    end

    def redirect_with_error(message)
      redirect_to admin_order_path(@seller_order.order), alert: message
    end
  end
end