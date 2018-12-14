# Sidekiq server
Sidekiq.configure_server do |config|
  concurrency = Sidekiq.options[:concurrency].to_i + 2

  config.redis = ConnectionPool.new(size: concurrency) do
    conn = Redis.new(url: Rails.application.secrets.redis_url_sidekiq)
    conn.call [:client, :setname, :sidekiq_server]
    conn
  end
end

# Sidekiq client
Sidekiq.configure_client do |config|
  concurrency = Sidekiq.options[:concurrency].to_i + 2
  config.redis = ConnectionPool.new(size: concurrency) do
    conn = Redis.new(url: Rails.application.secrets.redis_url_sidekiq)
    conn.call [:client, :setname, :sidekiq_client]
    conn
  end
end

# Sidekiq-Cron
schedule_file = "#{Rails.root}/config/schedule.yml"
if File.exists?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file) || {})
end
