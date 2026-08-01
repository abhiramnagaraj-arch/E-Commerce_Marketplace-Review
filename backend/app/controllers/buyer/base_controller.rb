module Buyer
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_buyer
  end
end