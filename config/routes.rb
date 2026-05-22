Rails.application.routes.draw do
  # Setup wizard (first-run only)
  get  "setup", to: "setup#show",   as: :setup
  post "setup", to: "setup#create"

  # Auth
  resource :session, only: [ :new, :create, :destroy ]
  get "auth/verify", to: "sessions#verify", as: :verify_session

  # Invitations
  resources :invitations, only: [ :index, :new, :create ]
  get "invitations/:token/accept", to: "invitations#accept", as: :accept_invitation
  post "invitations/:token/register", to: "invitations#register", as: :register_invitation

  # Notes journal
  get "notes", to: "notes#index", as: :notes_index

  # Core resources with nested notes
  concern :notable do
    resources :notes, only: [ :create, :edit, :update, :destroy ]
  end

  resources :goals, concerns: :notable do
    resources :memberships, only: [ :create, :destroy ]
  end
  resources :projects, concerns: :notable do
    resources :memberships, only: [ :create, :destroy ]
  end
  resources :todos, except: [ :index, :show ], concerns: :notable do
    member do
      patch :toggle
    end
  end
  resources :habits do
    member do
      patch :toggle_active
    end
  end
  resources :daily_pages, only: [], concerns: :notable

  # Daily page
  get "upcoming", to: "upcoming#index", as: :upcoming
  get "calendar", to: "calendar#show", as: :calendar
  root "daily#show"

  # Banner dismissals
  resources :dismissals, only: [ :create ]

  # User preferences
  patch "user/timezone", to: "users#update_timezone"

  # Account
  resource :account, only: [ :show ], controller: "account" do
    resource :export, only: [ :show ], module: :account
    resource :import, only: [ :new, :create ], module: :account
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
