# frozen_string_literal: true

require "test_helper"

class StandupTest < ActiveSupport::TestCase
  def setup
    @team = Team.create!(slack_user_team: "T1234567890")
    @user = User.create!(
      slack_user_id: "U1234567890",
      slack_user_team: "T1234567890",
      display_name: "testuser",
      real_name: "Test User"
    )
  end

  test "should create standup with valid attributes" do
    standup = Standup.create!(
      user: @user,
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      date: Date.current,
      yesterday: "Worked on feature A",
      today: "Will work on feature B",
      blocker: "No blockers"
    )

    assert standup.persisted?
    assert_equal @user.slack_user_id, standup.user_id
    assert_equal "C1234567890", standup.channel_id
    assert_equal "1234567890.123456", standup.message_ts
    assert_equal Date.current, standup.date
    assert_equal "Worked on feature A", standup.yesterday
    assert_equal "Will work on feature B", standup.today
    assert_equal "No blockers", standup.blocker
  end

  test "should create standup with nullable channel_id" do
    standup = Standup.create!(
      user: @user,
      channel_id: nil,
      message_ts: "1234567890.123456",
      date: Date.current,
      yesterday: "Worked on feature A",
      today: "Will work on feature B",
      blocker: "No blockers"
    )

    assert standup.persisted?
    assert_nil standup.channel_id
  end

  test "should belong to user" do
    standup = Standup.create!(
      user: @user,
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      date: Date.current,
      yesterday: "Worked on feature A",
      today: "Will work on feature B",
      blocker: "No blockers"
    )

    assert_equal @user, standup.user
    assert_includes @user.standups, standup
  end

  test "should allow empty blocker field" do
    standup = Standup.create!(
      user: @user,
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      date: Date.current,
      yesterday: "Worked on feature A",
      today: "Will work on feature B",
      blocker: ""
    )

    assert standup.persisted?
    assert_equal "", standup.blocker
  end

  test "should allow nil blocker field" do
    standup = Standup.create!(
      user: @user,
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      date: Date.current,
      yesterday: "Worked on feature A",
      today: "Will work on feature B",
      blocker: nil
    )

    assert standup.persisted?
    assert_nil standup.blocker
  end

  test "should have timestamps" do
    standup = Standup.create!(
      user: @user,
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      date: Date.current,
      yesterday: "Worked on feature A",
      today: "Will work on feature B",
      blocker: "No blockers"
    )

    assert_not_nil standup.created_at
    assert_not_nil standup.updated_at
  end

  test "should find standups by user" do
    standup1 = Standup.create!(
      user: @user,
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      date: Date.current,
      yesterday: "Worked on feature A",
      today: "Will work on feature B",
      blocker: "No blockers"
    )

    standup2 = Standup.create!(
      user: @user,
      channel_id: "C1234567890",
      message_ts: "1234567890.123457",
      date: Date.current,
      yesterday: "Worked on feature C",
      today: "Will work on feature D",
      blocker: "No blockers"
    )

    user_standups = Standup.where(user: @user)
    assert_includes user_standups, standup1
    assert_includes user_standups, standup2
    assert_equal 2, user_standups.count
  end

  test "should find standups by date" do
    standup = Standup.create!(
      user: @user,
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      date: Date.current,
      yesterday: "Worked on feature A",
      today: "Will work on feature B",
      blocker: "No blockers"
    )

    today_standups = Standup.where(date: Date.current)
    assert_includes today_standups, standup
  end

  test "should find standups by channel" do
    standup = Standup.create!(
      user: @user,
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      date: Date.current,
      yesterday: "Worked on feature A",
      today: "Will work on feature B",
      blocker: "No blockers"
    )

    channel_standups = Standup.where(channel_id: "C1234567890")
    assert_includes channel_standups, standup
  end

  test "should find standups from specific date range" do
    standup = Standup.create!(
      user: @user,
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      date: Date.current,
      yesterday: "Worked on feature A",
      today: "Will work on feature B",
      blocker: "No blockers"
    )

    week_ago = 1.week.ago.to_date
    today = Date.current

    range_standups = Standup.where(date: week_ago..today)
    assert_includes range_standups, standup
  end
end
