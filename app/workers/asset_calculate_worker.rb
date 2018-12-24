class AssetCalculateWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'asset_calculate', retry: true

  def perform(session_id)
    session = Session.where(id: session_id).take
    return if session.nil? || session.assets.exists?

    calculator = AssetCalculator.new(session)
    calculator.calculate_and_save

    session.calcs_ready  = true
    session.assets_value = session.assets.sum(:current_value)
    session.save!
  end
end
