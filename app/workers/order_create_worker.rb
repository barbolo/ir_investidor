class OrderCreateWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'order_create', retry: true

  def perform(attributes)
    order = Order.create(attributes)
    if order.errors.any?
      message = "Linha #{attributes['row']}. Operação descartada. #{order.errors.full_messages.join(', ')}."
      SessionLogCreateWorker.perform_async(attributes['session_id'], message)
    end

    if Session.counter(attributes['session_id'], 'orders_pending').decr(1) == 0
      OrderAfterCreateAllWorker.perform_async(attributes['session_id'])
    end
  end
end
