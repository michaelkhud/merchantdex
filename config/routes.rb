Rails.application.routes.draw do
  # Authentication routes
  resource :session, only: [:new, :create, :destroy]
  resources :passwords, param: :token, only: [:new, :create, :edit, :update]
  resource :registration, only: [:new, :create]
  resource :email_verification, only: [:new, :create]
  get "email_verification/verify/:token", to: "email_verifications#show", as: :verify_email
  
  # Dashboard
  get "dashboard", to: "dashboard#index"
  
  # Convenience routes
  get "login", to: "sessions#new"
  get "signup", to: "registrations#new"
  delete "logout", to: "sessions#destroy"
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"
end
