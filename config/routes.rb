Rusrails::Application.routes.draw do
  root to: "pages#index"

  get 'map' => 'pages#map'
  devise_for :users, controllers: {omniauth_callbacks: "omniauth_callbacks"}
  devise_scope :user do
    get '/users/auth/:provider' => 'omniauth_callbacks#passthru'
  end

  namespace "admin" do
    resources :pages
    resources :users
    resources :discussions
    resources :says
    root to: "dashboard#index"
  end

  resources :discussions, only: [:index, :new, :create] do
    resources :says, only: [:index, :create]
    get 'page/:page', action: :index, on: :collection
  end

  resources :says, only: [:edit, :update, :destroy] do
    post :preview, on: :collection
  end


  resource :search, only: :show, controller: :search

  get ":url_match" => "pages#show"
  match "*wrong" => "pages#not_found"
end
