class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_cart, :current_coupon

  private

  def current_cart
    Cart.find(session[:cart_id])
  rescue ActiveRecord::RecordNotFound, TypeError
    cart = Cart.create
    session[:cart_id] = cart.id
    cart
  end

  def current_coupon
    return nil unless session[:coupon_code].present?
    Coupon.find_by(code: session[:coupon_code], active: true)
  end
end
