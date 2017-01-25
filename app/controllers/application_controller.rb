class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  layout :layout_by_resource
  before_action :authenticate_user!

  private
  def layout_by_resource
    devise_controller? ? 'devise' : 'admin'
  end
end
