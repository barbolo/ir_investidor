class HoldingsController < ApplicationController
  def index
    @holdings = current_user.holdings.includes(:user_broker, :book).
                order('asset_name ASC').all
  end

  def calc
    Transaction.process_all(current_user)
    redirect_to holdings_path
  end
end
