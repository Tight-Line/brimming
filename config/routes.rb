require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users

  # Sidekiq Web UI - admin only
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/admin/sidekiq"
  end

  # LDAP authentication (custom implementation, not using OmniAuth routes)
  get "ldap/sign_in", to: "ldap_sessions#new", as: :ldap_sign_in
  post "ldap/sign_in", to: "ldap_sessions#create"

  # Admin namespace
  namespace :admin do
    get "/", to: "dashboard#show", as: :root
    resources :ldap_servers do
      resources :ldap_group_mappings, except: [ :index ] do
        member do
          post :add_space
          delete :remove_space
        end
      end
    end
    resources :embedding_providers do
      member do
        post :activate
        post :reindex
      end
    end
    resources :llm_providers do
      collection do
        get :ollama_models
      end
      member do
        post :activate
        post :set_default
      end
    end
    resource :search_settings, only: [ :show, :update ]
  end

  # Email verification (outside settings namespace for simpler URLs)
  get "verify_email", to: "email_verifications#show", as: :verify_email

  # User settings
  namespace :settings do
    resource :profile, only: [ :edit, :update ] do
      post :add_email
      delete :remove_email
      post :set_primary_email
      post :resend_verification
    end

    resources :subscriptions, only: [ :index ]

    # Keep LDAP spaces routes for now (will be removed in Phase 4)
    resources :ldap_spaces, only: [ :index ] do
      collection do
        post :opt_out
        post :opt_in
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  resources :articles, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    member do
      post :upvote
      delete :remove_vote
      delete :hard_delete
    end
    resources :comments, only: [ :create ], shallow: true
  end

  resources :questions, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    member do
      post :upvote
      post :downvote
      delete :remove_vote
      delete :hard_delete
    end
    resources :answers, only: [ :create, :edit, :update, :destroy ], shallow: true
    resources :comments, only: [ :create ], shallow: true
  end

  resources :answers, only: [] do
    member do
      post :upvote
      post :downvote
      delete :remove_vote
      delete :hard_delete
    end
    resources :comments, only: [ :create ], shallow: true
  end

  resources :comments, only: [ :edit, :update, :destroy ] do
    member do
      post :upvote
      delete :remove_vote
      delete :hard_delete
    end
    resources :comments, only: [ :create ], as: :replies
  end

  # Markdown preview endpoint
  post "markdown/preview", to: "markdown#preview"

  resources :spaces do
    member do
      get :moderators
      post :add_moderator
      delete :remove_moderator
      get :publishers
      post :add_publisher
      delete :remove_publisher
      get :search
      post :subscribe
      delete :unsubscribe
    end

    # Q&A Wizard - space-scoped for moderators
    resource :qa_wizard, only: [ :show, :create ], controller: "spaces/qa_wizard" do
      post :generate_titles
      get :select_title
      get :edit
      post :submit
      get :articles
    end
  end

  # Tags are scoped to spaces
  scope "/spaces/:space_slug" do
    resources :tags, only: [ :index, :show, :create, :destroy ], param: :slug do
      collection do
        get :search
      end
    end
  end

  # Global search
  get "search", to: "search#index", as: :search
  get "search/suggestions", to: "search#suggestions", as: :search_suggestions

  resources :users, only: [ :show ], param: :username do
    collection do
      get :search
    end
    member do
      get :posts_search, path: "search"
    end
  end

  resources :bookmarks, only: [ :index, :create, :update, :destroy ]
end
