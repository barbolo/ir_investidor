class CalculateTaxesMonthlyWorker
  include Sidekiq::Worker
  def perform
    start_date = Date.today.beginning_of_month
    User.pluck(:id).each do |id|
      CalculateTaxesWorker.perform_async(id, start_date)
    end
  end
end
