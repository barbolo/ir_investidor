# Sidekiq server
Sidekiq.configure_server do |config|
  concurrency = Sidekiq.options[:concurrency] || 5

  config.redis = ConnectionPool.new(size: concurrency + 2) do
    conn = Redis.new(url: Rails.application.secrets.redis_url, namespace: 'sidekiq_server')
    conn.client.call [:client, :setname, :sidekiq_server]
    conn
  end

  # Configure Database Connection Pool
  # https://github.com/mperham/sidekiq/wiki/Advanced-Options
  # http://julianee.com/rails-sidekiq-and-heroku/
  Rails.logger.info("DB Connection Pool size for Sidekiq Server before disconnect is: #{ActiveRecord::Base.connection.pool.instance_variable_get('@size')}")
  ActiveRecord::Base.connection_pool.disconnect!

  ActiveSupport.on_load(:active_record) do
    config = Rails.application.config.database_configuration[Rails.env]
    config['pool'] = concurrency
    ActiveRecord::Base.establish_connection(config)

    Rails.logger.info("DB Connection Pool size for Sidekiq Server is now: #{ActiveRecord::Base.connection.pool.instance_variable_get('@size')}")
  end
end

# Sidekiq client
Sidekiq.configure_client do |config|
  concurrency = Sidekiq.options[:concurrency] || 2
  config.redis = ConnectionPool.new(size: concurrency + 2) do
    conn = Redis.new(url: Rails.application.secrets.redis_url, namespace: 'sidekiq_client')
    conn.client.call [:client, :setname, :sidekiq_client]
    conn
  end
end

# Sidekiq-Cron
schedule_file = "#{Rails.root}/config/schedule.yml"
if File.exists?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
end
