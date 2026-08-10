class ApplicationController < ActionController::Base
  helper_method :current_cart, :cart_item_count
  before_action :configure_permitted_parameters, if: :devise_controller?

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
    promotion = Promotion.live.includes(:tiers).find_by(id: session[:promotion_id])
    promotion if promotion&.fits?(items, current_user)
  end

  def cart_item_count
    current_cart&.cart_items&.sum(:quantity) || 0
  end

  def paginate(collection, per_page:, param: :page)
    total = collection.count
    total_pages = (total.to_f / per_page).ceil
    total_pages = 1 if total_pages.zero?

    page = params[param].to_i
    page = 1 if page < 1
    page = total_pages if page > total_pages

    offset = (page - 1) * per_page

    records = if collection.is_a?(Array)
      collection[offset, per_page] || []
    else
      collection.offset(offset).limit(per_page)
    end

    [ records, page, total_pages, total ]
  end
end
