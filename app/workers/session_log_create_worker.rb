class SessionLogCreateWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'session_log_create', retry: true

  def perform(session_id, message)
    SessionLog.create!(session_id: session_id, message: message)
  end
end
