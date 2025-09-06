
class StandupReminder < ApplicationRecord
  validates :channel_id, presence: true
  validates :message_ts, presence: true
  validates :posted_at, presence: true

  scope :recent, -> { order(posted_at: :desc) }
  scope :by_channel, ->(channel_id) { where(channel_id: channel_id) }
end
