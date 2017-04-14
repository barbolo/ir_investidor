class HoldingsController < ApplicationController
  def index
    @holdings = current_user.holdings.order('asset_name ASC').all
  end
end
