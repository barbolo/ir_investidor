# Load environment variables
env_config = {
  'rails_env'   => ENV.fetch('RAILS_ENV') { 'development' },
  'threads_min' => ENV.fetch("WEB_THREADS_MIN") { 5 }.to_i,
  'threads_max' => ENV.fetch("WEB_THREADS_MAX") { 5 }.to_i,
  'web_port'    => ENV.fetch("WEB_PORT") { 3000 }.to_i,
}

# Find the Rails application root directory
app_dir = File.expand_path("../..", __FILE__)
directory app_dir

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads env_config['threads_min'], env_config['threads_max']

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port env_config['web_port']

# Specifies the `environment` that Puma will run in.
#
environment env_config['rails_env']

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
# preload_app!

# Allow puma to be restarted by `rails restart` command.
# plugin :tmp_restart
