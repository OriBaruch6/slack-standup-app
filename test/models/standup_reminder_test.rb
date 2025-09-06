# frozen_string_literal: true

require "test_helper"

class StandupReminderTest < ActiveSupport::TestCase
  test "should create standup reminder with valid attributes" do
    reminder = StandupReminder.create!(
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      posted_at: Time.current
    )

    assert reminder.persisted?
    assert_equal "C1234567890", reminder.channel_id
    assert_equal "1234567890.123456", reminder.message_ts
    assert_not_nil reminder.posted_at
  end

  test "should have timestamps" do
    reminder = StandupReminder.create!(
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      posted_at: Time.current
    )

    assert_not_nil reminder.created_at
    assert_not_nil reminder.updated_at
  end

  test "should find reminders by channel" do
    reminder = StandupReminder.create!(
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      posted_at: Time.current
    )

    channel_reminders = StandupReminder.where(channel_id: "C1234567890")
    assert_includes channel_reminders, reminder
  end

  test "should find reminders by posted_at" do
    reminder = StandupReminder.create!(
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      posted_at: Time.current
    )

    today_reminders = StandupReminder.where(posted_at: Time.current.beginning_of_day..Time.current.end_of_day)
    assert_includes today_reminders, reminder
  end

  test "should find reminders by message_ts" do
    reminder = StandupReminder.create!(
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      posted_at: Time.current
    )

    found_reminder = StandupReminder.find_by(message_ts: "1234567890.123456")
    assert_equal reminder, found_reminder
  end

  test "should find reminders from specific date range" do
    reminder = StandupReminder.create!(
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      posted_at: Time.current
    )

    week_ago = 1.week.ago
    today = Time.current

    range_reminders = StandupReminder.where(posted_at: week_ago..today)
    assert_includes range_reminders, reminder
  end
end
