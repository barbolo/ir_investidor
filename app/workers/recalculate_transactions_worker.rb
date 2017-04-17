class RecalculateTransactionsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'calculating'
  def perform(user_id, start_date = nil)
    user = User.find(user_id)
    user.start_calculations_signal # ensure signal was emitted

    if !start_date
      user.holdings.destroy_all
      user.taxes.destroy_all
      transactions = user.transactions
    else
      user.taxes.where('period >= ?', start_date.beginning_of_month).destroy_all
      user.holdings.where('last_operation_at >= ?', start_date).destroy_all
      transactions = user.transactions.where('operation_at >= ?', start_date)
    end

    transactions.find_each do |tr|
      tr.process
    end

    user.stop_calculations_signal

    CalculateTaxesWorker.perform_async(user.id, start_date)
  end
end
