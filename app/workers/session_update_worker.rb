class SessionUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'session_update', retry: true

  def perform(session_id, attributes={})
    session = Session.where(id: session_id).take
    return if session.nil? # probably destroyed
    session.update!(attributes)
  end
end
