Rails.application.routes.draw do
  root "products#index"

  resources :categories
  resources :products

  resource :cart, only: [:show] do
    post :add_item
    delete :remove_item
    patch :update_quantity
    post :apply_coupon
    delete :remove_coupon
  end

  resources :orders, only: [:new, :create, :show, :index]

  get "up" => "rails/health#show", as: :rails_health_check
end
