class TransactionsController < ApplicationController
  def index
    @orders = current_session.orders.order(:ordered_at)
  end
end
