class HoldingsController < ApplicationController
  def index
    @holdings = current_user.holdings.includes(:user_broker, :book).
                order('asset_name ASC').all
  end
end
