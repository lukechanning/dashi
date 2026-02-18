Rails.application.routes.draw do
  # Auth
  resource :session, only: [:new, :create, :destroy]
  get "auth/verify", to: "sessions#verify", as: :verify_session

  # Core resources
  resources :goals
  resources :projects
  resources :todos, except: [:index, :show] do
    member do
      patch :toggle
    end
  end

  # Daily page
  root "daily#show"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
