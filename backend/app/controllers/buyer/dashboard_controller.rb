module Buyer
  class DashboardController < BaseController
    def show
      @orders = current_user.orders.order(created_at: :desc).limit(5)
    end
  end
end