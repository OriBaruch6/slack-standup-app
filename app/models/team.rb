# frozen_string_literal: true

class Team < ApplicationRecord
  validates :slack_user_team, presence: true, uniqueness: true

  has_many :users, foreign_key: :slack_user_team, primary_key: :slack_user_team, dependent: :destroy
  has_many :standups, through: :users
  has_many :standup_reminders, dependent: :destroy
end
