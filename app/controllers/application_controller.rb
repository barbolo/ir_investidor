class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout 'admin' # use admin as the default application layout
end
