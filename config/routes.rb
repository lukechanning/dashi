Rails.application.routes.draw do
  # Auth
  resource :session, only: [:new, :create, :destroy]
  get "auth/verify", to: "sessions#verify", as: :verify_session

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "daily#show"
end
