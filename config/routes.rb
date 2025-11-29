Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  resources :questions, only: [ :index, :show, :new, :create ] do
    member do
      post :upvote
      post :downvote
      delete :remove_vote
    end
    resources :answers, only: [ :create ], shallow: true
    resources :comments, only: [ :create ], shallow: true
  end

  resources :answers, only: [] do
    member do
      post :upvote
      post :downvote
      delete :remove_vote
    end
    resources :comments, only: [ :create ], shallow: true
  end

  resources :comments, only: [] do
    member do
      post :upvote
      delete :remove_vote
    end
    resources :comments, only: [ :create ], as: :replies
  end

  # Markdown preview endpoint
  post "markdown/preview", to: "markdown#preview"

  resources :spaces, only: [ :index, :show ]

  resources :users, only: [ :show ], param: :username
end
