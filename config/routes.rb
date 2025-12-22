# frozen_string_literal: true

Rails.application.routes.draw do
  # Devise authentication routes
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    confirmations: "users/confirmations",
    passwords: "users/passwords"
  }

  # Health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "pages#index5"

  # Static pages
  get "about", to: "pages#about"
  get "how-it-works", to: "pages#how_it_works"
  get "pricing", to: "pages#pricing"
  get "contact", to: "pages#contact"

  # Homepage design variants (for review)
  get "index1", to: "pages#index1"
  get "index2", to: "pages#index2"
  get "index3", to: "pages#index3"
  get "index4", to: "pages#index4"
  get "index5", to: "pages#index5"

  # Legal documents (public access)
  get "terms", to: "legal_documents#terms", as: :terms
  get "privacy", to: "legal_documents#privacy", as: :privacy
  post "accept-terms", to: "legal_documents#accept", as: :accept_terms

  # Authenticated user routes
  authenticate :user do
    # Dashboard
    get "dashboard", to: "dashboard#show", as: :dashboard

    # Onboarding
    get "onboarding", to: "onboarding#show", as: :onboarding
    post "onboarding", to: "onboarding#update"
    post "onboarding/complete", to: "onboarding#complete", as: :complete_onboarding

    # User profile
    resource :profile, only: [:show, :edit, :update] do
      get :preferences
      patch :update_preferences
    end

    # Entities (Individual, Company, SMSF)
    resources :entities do
      member do
        post :make_default
        post :verify
      end
    end

    # Subscription management
    resource :subscription, only: [:show, :edit, :update] do
      post :checkout
      post :portal
      get :success
      get :cancel
    end

    # KYC Verification
    resource :kyc_verification, only: [:show, :create, :update], path: "kyc" do
      post :submit
    end

    # Co-users
    resources :co_users, only: [:index, :show, :destroy] do
      collection do
        get :invitations
      end
    end

    resources :co_user_invitations, only: [:new, :create, :destroy] do
      member do
        post :resend
        post :revoke
      end
    end

    # Accept co-user invitation (token-based)
    get "invitations/:token", to: "co_user_invitations#accept", as: :accept_co_user_invitation
    post "invitations/:token/confirm", to: "co_user_invitations#confirm"

    # Buyer-specific routes
    namespace :buyer do
      resource :profile, only: [:show, :edit, :update]
      resource :journey, only: [:show], controller: 'journey'
      resources :offers, only: [:index, :show]
      resources :saved_searches
      resources :saved_properties, only: [:index, :create, :destroy]
      resources :property_alerts, only: [:index, :create, :update, :destroy]
    end

    # Seller-specific routes
    namespace :seller do
      resource :profile, only: [:show, :edit, :update]
      resource :journey, only: [:show], controller: 'journey'
      resources :properties do
        member do
          post :publish
          post :unpublish
          post :archive
        end
        resources :offers, only: [:index, :show] do
          member do
            post :accept
            post :reject
            post :counter
          end
        end
      end
    end

    # Service Provider routes
    namespace :provider do
      resource :profile, only: [:show, :edit, :update]
      resources :leads, only: [:index, :show, :update]
      resources :jobs, only: [:index, :show, :update]
    end

    # AI Assistants
    namespace :ai do
      resources :conversations, only: [:index, :show, :create] do
        member do
          post :message
          post :rate
        end
      end
    end

    # Reviews
    resources :reviews, only: [:index, :show, :create] do
      member do
        post :respond
      end
      resources :disputes, controller: "review_disputes", only: [:new, :create]
    end

    # Notifications
    resources :notifications, only: [:index, :show] do
      collection do
        post :mark_all_read
      end
      member do
        post :mark_read
      end
    end

    # Messages
    resources :conversations, only: [:index, :show, :create] do
      resources :messages, only: [:create]
    end

    # Documents
    resources :documents, only: [:index, :show, :create, :destroy]

    # Checklist progress (for journey)
    resources :checklist_progress, only: [] do
      member do
        post :toggle
      end
    end
  end

  # Public property browsing
  resources :properties, only: [:index] do
    collection do
      # SEO-friendly nested property URLs: /properties/au/:state/:suburb/:slug
      get "au/:state/:suburb/:slug", action: :show, as: :seo
      post "au/:state/:suburb/:slug/enquire", action: :enquire, as: :enquire_seo
      post "au/:state/:suburb/:slug/love", action: :love, as: :love_seo
      delete "au/:state/:suburb/:slug/unlove", action: :unlove, as: :unlove_seo
      get "au/:state/:suburb/:slug/offers/new", to: "property_offers#new", as: :new_seo_offer
      post "au/:state/:suburb/:slug/offers", to: "property_offers#create", as: :seo_offers
    end
  end

  # Fallback for legacy numeric IDs (redirects to SEO URL)
  get "properties/:id", to: "properties#show_legacy", as: :property, constraints: { id: /\d+/ }

  # Map search
  get "search", to: "properties#search", as: :property_search
  get "map", to: "properties#map", as: :property_map

  # Service providers directory
  resources :service_providers, only: [:index, :show], path: "providers"

  # Admin namespace
  namespace :admin do
    root to: "dashboard#show"

    # Dashboard
    get "dashboard", to: "dashboard#show"

    # Business Intelligence Section
    namespace :business do
      root to: "dashboard#show"
      get "dashboard", to: "dashboard#show", as: :dashboard
      get "revenue", to: "revenue#show", as: :revenue
      get "users", to: "users#show", as: :users
      get "transactions", to: "transactions#show", as: :transactions
    end

    # System Health Section
    namespace :system do
      root to: "dashboard#show"
      get "dashboard", to: "dashboard#show", as: :dashboard
      get "usage", to: "usage#show", as: :usage
      get "ai", to: "ai#show", as: :ai
      get "audit", to: "audit#show", as: :audit
    end

    # Users management
    resources :users do
      member do
        post :impersonate
        post :suspend
        post :unsuspend
        get :activity
        get :ai_conversations
      end
      collection do
        get :buyers
        get :sellers
        get :providers
        get :admins
      end
    end

    # Stop impersonation
    delete "stop_impersonating", to: "users#stop_impersonating"

    # Properties management
    resources :properties do
      member do
        post :approve
        post :reject
        post :feature
        post :unfeature
      end
      collection do
        get :pending
        get :reported
      end
    end

    # Transactions
    resources :transactions, only: [:index, :show] do
      collection do
        get :active
        get :completed
        get :disputes
      end
    end

    # Reviews moderation
    resources :reviews do
      member do
        post :publish
        post :hold
        post :remove
      end
      collection do
        get :pending
        get :held
      end
    end

    # Review disputes
    resources :review_disputes, only: [:index, :show] do
      member do
        post :start_review
        post :uphold
        post :reject
      end
    end

    # AI System
    namespace :ai do
      resources :conversations, only: [:index, :show] do
        member do
          get :export
        end
        collection do
          get :export_all
        end
      end

      resources :voice_settings, only: [:index, :show, :edit, :update] do
        member do
          post :test
          post :reset
        end
      end

      get "analytics", to: "analytics#show"
    end

    # Audit logs
    resources :audit_logs, only: [:index, :show] do
      collection do
        get :export
      end
    end

    # Legal documents
    resources :legal_documents do
      member do
        post :publish
        get :preview
      end
      collection do
        get :history
      end
    end

    # Platform settings
    resource :settings, only: [:show, :update] do
      get :integrations
      patch :update_integrations
    end

    # Analytics
    get "analytics", to: "analytics#show"
    get "analytics/users", to: "analytics#users"
    get "analytics/properties", to: "analytics#properties"
    get "analytics/transactions", to: "analytics#transactions"

    # KYC verification requests
    resources :kyc_verifications, only: [:index, :show] do
      member do
        post :approve
        post :reject
      end
    end

    # Service provider verifications
    resources :provider_verifications, only: [:index, :show] do
      member do
        post :approve
        post :reject
      end
    end
  end

  # Webhooks (no authentication required)
  namespace :webhooks do
    post "stripe", to: "stripe#create"
  end

  # API namespace (for future mobile app)
  namespace :api do
    namespace :v1 do
      # Investor analytics API (public, rate-limited)
      namespace :investor do
        resources :postcodes, only: [:index, :show] do
          member do
            get :projections
            get :score_breakdown
            get :crime
            get :property_score
            get :value_projection
          end
        end
        resources :suburbs, only: [:index, :show] do
          member do
            get :projections
            get :crime
            get :property_score
          end
        end
      end
    end
  end

  # Letter opener for development emails
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # Catch-all for 404s (must be last)
  match "*path", to: "errors#not_found", via: :all, constraints: lambda { |req|
    !req.path.start_with?("/rails/active_storage")
  }
end
