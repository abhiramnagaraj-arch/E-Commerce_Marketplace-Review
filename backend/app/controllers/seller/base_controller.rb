module Seller
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_seller
  end
end