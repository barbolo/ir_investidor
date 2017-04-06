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
end
