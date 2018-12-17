class Session < ApplicationRecord
  has_one_attached :sheet, dependent: :destroy
  has_many :session_logs, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :assets, dependent: :destroy

  validate :validate_sheet

  before_create :before_create_hook
  after_create :after_create_hook

  def self.counter(session_id, attribute)
    Counter.new("session/#{session_id}/#{attribute}")
  end

  private
    def validate_sheet
      if !sheet.attached? || Roo::CLASS_FOR_EXTENSION[sheet.filename.extension.to_sym].nil?
        errors.add(:sheet)
      end
    end

    def before_create_hook
      self.secret = SecureRandom.hex(32)
      self.expire_at = Time.now + 1.hour
    end

    def after_create_hook
      SheetParseWorker.perform_async(id)
      SessionExpireWorker.perform_in(1.hour, id)
    end

    def destroy
      ActiveStorage::Blob.where(key: sheet.key).take.try(:destroy) if sheet.attached?
      super
    end
end
