Rails.application.routes.draw do
  # Auth
  resource :session, only: [:new, :create, :destroy]
  get "auth/verify", to: "sessions#verify", as: :verify_session

  # Invitations
  resources :invitations, only: [:index, :new, :create]
  get "invitations/:token/accept", to: "invitations#accept", as: :accept_invitation
  post "invitations/:token/register", to: "invitations#register", as: :register_invitation

  # Core resources with nested notes
  concern :notable do
    resources :notes, only: [:create, :edit, :update, :destroy]
  end

  resources :goals, concerns: :notable do
    resources :memberships, only: [:create, :destroy]
  end
  resources :projects, concerns: :notable do
    resources :memberships, only: [:create, :destroy]
  end
  resources :todos, except: [:index, :show], concerns: :notable do
    member do
      patch :toggle
    end
  end
  resources :daily_pages, only: [], concerns: :notable

  # Daily page
  root "daily#show"

  # User preferences
  patch "user/timezone", to: "users#update_timezone"

  # Account
  get "account", to: "account#show", as: :account

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
