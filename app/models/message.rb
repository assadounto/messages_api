class Message < ApplicationRecord
  enum :status,         { pending: 0, classified: 1, failed: 2 }, default: :pending
  enum :classification, { general: 0, important: 1 }, allow_nil: true

  validates :subject, :body, :sender, presence: true

  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.status ||= :pending
    self.classification_attempts ||= 0
  end
end
