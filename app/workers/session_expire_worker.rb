class SessionExpireWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'session_expire', retry: true

  def perform(session_id)
    session = Session.where(id: session_id).take
    return if session.nil? # already destroyed
    session.destroy!
  end
end
