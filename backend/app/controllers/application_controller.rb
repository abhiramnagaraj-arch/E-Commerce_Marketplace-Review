class ApplicationController < ActionController::Base
  helper_method :current_cart, :cart_item_count
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |params|
      permitted = params.permit(:name, :email, :password, :password_confirmation, :role)
      permitted[:role] = "buyer" unless %w[buyer seller].include?(permitted[:role])
      permitted
    end

    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def require_buyer
    redirect_to root_path, alert: "Buyer access required." unless current_user&.buyer?
  end

  def require_seller
    redirect_to root_path, alert: "Seller access required." unless current_user&.seller?
  end

  def require_admin
    redirect_to root_path, alert: "Admin access required." unless current_user&.admin?
  end

  private

  def current_cart
    return unless current_user&.buyer?

    current_user.cart || current_user.create_cart!
  end

  def current_promotion(items)
    code = session[:promotion_code]
    promotion = Promotion.best_for(items, code: code)
    return promotion if promotion || code.blank?

    session.delete(:promotion_code)
    Promotion.best_for(items)
  end

  def cart_item_count
    current_cart&.cart_items&.sum(:quantity) || 0
  end
end