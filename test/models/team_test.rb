# frozen_string_literal: true

require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "should create team with valid attributes" do
    team = Team.create!(slack_user_team: "T1234567890")

    assert team.persisted?
    assert_equal "T1234567890", team.slack_user_team
  end

  test "should have many users" do
    team = Team.create!(slack_user_team: "T1234567890")

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

    assert_includes team.users, user1
    assert_includes team.users, user2
    assert_equal 2, team.users.count
  end

  test "should find team by slack_user_team" do
    team = Team.create!(slack_user_team: "T1234567890")

    found_team = Team.find_by(slack_user_team: "T1234567890")
    assert_equal team, found_team
  end

  test "should have timestamps" do
    team = Team.create!(slack_user_team: "T1234567890")

    assert_not_nil team.created_at
    assert_not_nil team.updated_at
  end

  test "should validate presence of slack_user_team" do
    team = Team.new(slack_user_team: "")

    assert_not team.valid?
    assert_includes team.errors[:slack_user_team], "can't be blank"
  end

  test "should validate uniqueness of slack_user_team" do
    Team.create!(slack_user_team: "T1234567890")
    team = Team.new(slack_user_team: "T1234567890")

    assert_not team.valid?
    assert_includes team.errors[:slack_user_team], "has already been taken"
  end

  test "should find or create team" do
    team1 = Team.find_or_create_by(slack_user_team: "T1234567890")
    team2 = Team.find_or_create_by(slack_user_team: "T1234567890")

    assert_equal team1, team2
    assert_equal 1, Team.where(slack_user_team: "T1234567890").count
  end

  test "should create multiple teams" do
    team1 = Team.create!(slack_user_team: "T1234567890")
    team2 = Team.create!(slack_user_team: "T1234567891")

    assert_not_equal team1, team2
    assert_equal 2, Team.count
  end
end
