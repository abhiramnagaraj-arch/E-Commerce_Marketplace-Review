Rails.application.routes.draw do
  devise_for :users
  root "products#index"

  resources :categories, only: %i[index show]
  resources :products, only: %i[index show]

  namespace :buyer do
    root "dashboard#show"
    resource :cart, only: :show do
      post :add_item
      delete :remove_item
      patch :increment_item
      patch :decrement_item
      post :pick_offer
    end
    resources :orders, only: %i[index show new create] do
      patch :cancel, on: :member
    end
  end

  namespace :seller do
    root "dashboard#show"
    resources :products
    resources :categories, only: %i[index show]
    resources :orders, only: %i[index show] do
      patch :process_order, on: :member
      patch :ship, on: :member
      patch :deliver, on: :member
      patch :reject, on: :member
    end
  end

  namespace :admin do
    root "dashboard#show"
    resources :categories, except: :show
    resources :promotions, except: %i[show destroy] do
      patch :toggle, on: :member
    end
    resources :orders, only: %i[index show]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
