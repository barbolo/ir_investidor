require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module IrInvestidor
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Set time zone
    config.time_zone = 'Brasilia'

    # Set default locale
    config.i18n.default_locale = 'pt-BR'

    # Use Redis as cache store
    config.cache_store = :redis_cache_store, {
      driver: :hiredis,
      compress: true,
      url: Rails.application.secrets.redis_url_cache
    }

    # Use CacheStore (that uses Redis) as the session store
    config.session_store ActionDispatch::Session::CacheStore, expire_after: 2.days
  end
end
