class ApplicationController < ActionController::Base
  protect_from_forgery

  before_action :authenticate!

  def authenticate!
    redirect_to(root_path, alert: 'Sua sessão expirou!') if current_session.nil?
  end

  def current_session
    @current_session ||= {session: Session.where(secret: params[:secret]).take}
    @current_session[:session]
  end
  helper_method :current_session
end
