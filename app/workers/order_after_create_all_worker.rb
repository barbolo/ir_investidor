class OrderAfterCreateAllWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'order_after_create_all', retry: true

  def perform(session_id)
    if Session.counter(session_id, 'orders_pending').get > 0
      return OrderAfterCreateAllWorker.perform_in(10.seconds, session_id)
    end

    session_orders_were_ready = ActiveRecord::Base.transaction do
      session = Session.where(id: session_id).take

      if session.nil? || session.orders_ready
        true
      else
        session.orders_ready = true
        session.orders_count = session.orders.count
        session.save!
        false
      end
    end

    return if session_orders_were_ready # avoid concurrent executions

    # we can now safely start calculations
    AssetCalculateWorker.perform_async(session_id)
  end
end
