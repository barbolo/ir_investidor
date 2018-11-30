# We will optimise the number of connections to our Redis server by using a
# connection pool.

# See more at:
# http://stackoverflow.com/questions/28113940/what-is-the-best-way-to-use-redis-in-a-multi-threaded-rails-environment-puma

unless defined?(REDIS)
  REDIS = ConnectionPool.new(size: 20) do
    # Create a Redis connection
    conn = Redis.new(url: Rails.application.secrets.redis_url_app, driver: :hiredis)
    # Set a name to identify this connection
    conn.call [:client, :setname, :connection_pool_redis_app]
    # Return the connection to the pool
    conn
  end
end

# Use a Redis connection from the connection pool:
# REDIS.with { |conn| conn.do_something }
