class PortfolioController < ApplicationController
  def index
    @books = current_user.books_tree
    @holdings = current_user.holdings.order('asset_name ASC').all
  end

  def recalc
    current_user.recalculate!
    redirect_to portfolio_path
  end
end
