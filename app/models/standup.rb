# frozen_string_literal: true

class Standup < ApplicationRecord
  validates :user_id, presence: true
  # validates :channel_id, presence: true # Not available in view_submission payloads
  validates :date, presence: true
  validates :yesterday, presence: true
  validates :today, presence: true

  belongs_to :user, foreign_key: :user_id, primary_key: :slack_user_id

  scope :by_date, ->(date) { where(date: date) }
  scope :by_channel, ->(channel_id) { where(channel_id: channel_id) }
  scope :recent, -> { order(created_at: :desc) }

  def self.today
    by_date(Date.current)
  end
end
