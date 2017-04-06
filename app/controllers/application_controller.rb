class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  layout :layout_by_resource
  before_action :authenticate_user!

  protected
    def parse_dates(hash, *names)
      names.each do |name|
        next if hash[name].blank?
        hash[name] = Date.parse(hash[name], start=Date::ITALY)
      end
    end

    def parse_decimals(hash, *names)
      names.each do |name|
        next if hash[name].blank?
        hash[name] = BigDecimal.new(hash[name].gsub('.', '').gsub(',', '.'))
      end
    end

  private
    def layout_by_resource
      devise_controller? ? 'devise' : 'admin'
    end
end
