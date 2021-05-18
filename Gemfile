source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.4'

# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.4.10'

# Use Puma as the app server
gem 'puma', '~> 4.3.8'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.8'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5.2.1'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '~> 1.3.2', require: false

# Use Redis as a in-memory data structure store and for cache/session store
gem 'hiredis'
gem 'redis', '~> 4.0'
gem 'connection_pool'

# Use Sidekiq for background/asynchronous jobs
gem 'sidekiq'
gem 'sidekiq-limit_fetch'
gem 'sidekiq-cron'

# Read Spreadsheets
gem "roo", "~> 2.8.3"
gem 'roo-xls'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  # Use RSpec as the test framework
  gem 'rspec-rails', '~> 3.8'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
end
