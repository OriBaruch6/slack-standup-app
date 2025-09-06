# frozen_string_literal: true

class User < ApplicationRecord
  validates :slack_user_id, presence: true, uniqueness: true
  validates :slack_user_team, presence: true
  validates :display_name, presence: true
  validates :real_name, presence: true

  has_many :standups, dependent: :destroy
  belongs_to :team, foreign_key: :slack_user_team, primary_key: :slack_user_team

  scope :by_team, ->(team_id) { where(slack_user_team: team_id) }
end
