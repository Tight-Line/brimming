Rails.application.routes.draw do
  devise_for :users

  # LDAP authentication (custom implementation, not using OmniAuth routes)
  get "ldap/sign_in", to: "ldap_sessions#new", as: :ldap_sign_in
  post "ldap/sign_in", to: "ldap_sessions#create"

  # Admin namespace
  namespace :admin do
    resources :ldap_servers do
      resources :ldap_group_mappings, except: [ :index ] do
        member do
          post :add_space
          delete :remove_space
        end
      end
    end
  end

  # User settings
  namespace :settings do
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
    end
  end

  resources :users, only: [ :show ], param: :username do
    collection do
      get :search
    end
  end
end
