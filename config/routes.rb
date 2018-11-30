require 'sidekiq/web'
Sidekiq::Web.set :session_secret, Rails.application.secrets.secret_key_base
Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(Rails.application.secrets.sidekiq_username)) &&
  ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(Rails.application.secrets.sidekiq_password))
end if Rails.env.production?

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Sidekiq Web UI
  mount Sidekiq::Web => '/sidekiq-admin'
end
