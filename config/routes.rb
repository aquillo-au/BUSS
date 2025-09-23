Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "guests#index"
  get "/admin", to: "guests#history", as: :admin

  resources :volunteers, only: [:index, :create] do
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

  resources :sign_ins, only: [:destroy] do
    member do
      patch :leave
    end
  end

  resources :incidents, only: [ :index, :new, :create, :destroy ]
  resources :notes, only: [ :new, :create ]

  # Reports
  get "reports/category_averages", to: "reports#category_averages", as: :reports_category_averages
  get "reports/people/:id/sign_ins", to: "reports#person_sign_ins", as: :reports_person_sign_ins
end
