require 'sidekiq/web'
Sidekiq::Web.set :session_secret, Rails.application.secrets.secret_key_base
Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(Rails.application.secrets.sidekiq_username)) &&
  ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(Rails.application.secrets.sidekiq_password))
end if Rails.env.production?

Rails.application.routes.draw do
  root to: 'sessions#new'

  resources :sessions, path: 'calculando', param: :secret, except: [:index, :edit, :update]

  get 'operacoes/:secret', to: 'transactions#index', as: :transactions
  get 'posicoes/:secret', to: 'assets#index', as: :assets
  get 'impostos/:period/:secret', to: 'taxes#show', as: :taxes
  get 'declaracao/:secret', to: 'taxes#declaracao', as: :declaracao

  # Sidekiq Web UI
  mount Sidekiq::Web => '/sidekiq'
end
