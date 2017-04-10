require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  root to: 'dashboard#index'

  get 'account', to: 'dashboard#account'
  patch 'account', to: 'dashboard#update_account'

  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    passwords: 'users/passwords',
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    unlocks: 'users/unlocks',
  }

  resources :books, only: [:index, :new, :create] do
    patch 'update_all', on: :collection
  end

  resources :user_brokers, except: [:show]

  resources :transactions, except: [:show]

  get 'holdings', to: 'holdings#index', as: :holdings
  get 'holdings/calc', to: 'holdings#calc', as: :holdings_calc

  get 'portfolio', to: 'portfolio#index', as: :portfolio
  get 'portfolio/calc', to: 'portfolio#calc', as: :portfolio_calc

  get 'tax', to: 'tax#index', as: :tax

  # Sidekiq Web UI
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq-admin'
  end
  Sidekiq::Web.set :session_secret, Rails.application.secrets.secret_key_base
end
