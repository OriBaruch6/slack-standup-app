# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @team = Team.create!(slack_user_team: "T1234567890")
  end

  test "should create user with valid attributes" do
    user = User.create!(
      slack_user_id: "U1234567890",
      slack_user_team: "T1234567890",
      display_name: "testuser",
      real_name: "Test User"
    )

    assert user.persisted?
    assert_equal "U1234567890", user.slack_user_id
    assert_equal "T1234567890", user.slack_user_team
    assert_equal "testuser", user.display_name
    assert_equal "Test User", user.real_name
  end

  test "should belong to team" do
    user = User.create!(
      slack_user_id: "U1234567890",
      slack_user_team: "T1234567890",
      display_name: "testuser",
      real_name: "Test User"
    )

    assert_equal @team, user.team
    assert_includes @team.users, user
  end

  test "should have many standups" do
    user = User.create!(
      slack_user_id: "U1234567890",
      slack_user_team: "T1234567890",
      display_name: "testuser",
      real_name: "Test User"
    )

    standup1 = Standup.create!(
      user: user,
      channel_id: "C1234567890",
      message_ts: "1234567890.123456",
      date: Date.current,
      yesterday: "Worked on feature A",
      today: "Will work on feature B",
      blocker: "No blockers"
    )

    standup2 = Standup.create!(
      user: user,
      channel_id: "C1234567890",
      message_ts: "1234567890.123457",
      date: Date.current,
      yesterday: "Worked on feature C",
      today: "Will work on feature D",
      blocker: "No blockers"
    )

    assert_includes user.standups, standup1
    assert_includes user.standups, standup2
    assert_equal 2, user.standups.count
  end

  test "should find user by slack_user_id" do
    user = User.create!(
      slack_user_id: "U1234567890",
      slack_user_team: "T1234567890",
      display_name: "testuser",
      real_name: "Test User"
    )

    found_user = User.find_by(slack_user_id: "U1234567890")
    assert_equal user, found_user
  end

  test "should find users by team" do
    user1 = User.create!(
      slack_user_id: "U1234567890",
      slack_user_team: "T1234567890",
      display_name: "testuser1",
      real_name: "Test User 1"
    )

    user2 = User.create!(
      slack_user_id: "U1234567891",
      slack_user_team: "T1234567890",
      display_name: "testuser2",
      real_name: "Test User 2"
    )

    team_users = User.where(slack_user_team: "T1234567890")
    assert_includes team_users, user1
    assert_includes team_users, user2
    assert_equal 2, team_users.count
  end

  test "should have timestamps" do
    user = User.create!(
      slack_user_id: "U1234567890",
      slack_user_team: "T1234567890",
      display_name: "testuser",
      real_name: "Test User"
    )

    assert_not_nil user.created_at
    assert_not_nil user.updated_at
  end

  test "should validate presence of display_name" do
    user = User.new(
      slack_user_id: "U1234567890",
      slack_user_team: "T1234567890",
      display_name: "",
      real_name: "Test User"
    )

    assert_not user.valid?
    assert_includes user.errors[:display_name], "can't be blank"
  end

  test "should validate presence of real_name" do
    user = User.new(
      slack_user_id: "U1234567890",
      slack_user_team: "T1234567890",
      display_name: "testuser",
      real_name: ""
    )

    assert_not user.valid?
    assert_includes user.errors[:real_name], "can't be blank"
  end

  test "should validate presence of slack_user_id" do
    user = User.new(
      slack_user_id: "",
      slack_user_team: "T1234567890",
      display_name: "testuser",
      real_name: "Test User"
    )

    assert_not user.valid?
    assert_includes user.errors[:slack_user_id], "can't be blank"
  end

  test "should validate presence of slack_user_team" do
    user = User.new(
      slack_user_id: "U1234567890",
      slack_user_team: "",
      display_name: "testuser",
      real_name: "Test User"
    )

    assert_not user.valid?
    assert_includes user.errors[:slack_user_team], "can't be blank"
  end
end
