Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  get  "login",  to: "sessions#new",     as: :login
  post "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  # Landing page
  root "pages#landing"
  get "/check-in", to: "guests#index", as: :check_in
  get "/admin", to: "guests#history", as: :admin

  resources :volunteers, only: [ :index, :create ] do
    member do
      post :arrive
    end
  end

  resources :guests do
    member do
      post :merge
      post :arrive
      patch :archive
      patch :unarchive
    end
    collection do
      get :history
    end
  end

  resources :sign_ins, only: [ :destroy, :edit, :update ] do
    member do
      patch :leave
    end
  end

  resources :incidents, only: [ :index, :new, :create, :destroy ]
  resources :notes, only: [ :new, :create ]

  get "reports/category_averages", to: "reports#category_averages", as: :reports_category_averages
  get "reports/people/:id/sign_ins", to: "reports#person_sign_ins", as: :reports_person_sign_ins
end
