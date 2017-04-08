class PortfolioController < ApplicationController
  def index
    @books = current_user.books_tree
    @holdings = current_user.holdings.includes(:user_broker, :book).
                order('asset_name ASC').all
  end

  def calc
    Transaction.process_all(current_user)
    redirect_to portfolio_path
  end
end
