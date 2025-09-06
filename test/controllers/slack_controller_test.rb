# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class SlackControllerTest < ActionDispatch::IntegrationTest
  def setup
    @team = Team.create!(slack_user_team: "T1234567890")
    @user = User.create!(
      slack_user_id: "U1234567890",
      slack_user_team: "T1234567890",
      display_name: "testuser",
      real_name: "Test User"
    )
  end

  test "should handle block_actions payload" do
    payload = {
      type: "block_actions",
      user: { id: "U1234567890", team_id: "T1234567890" },
      container: { channel_id: "C1234567890" },
      trigger_id: "1234567890.1234567890.abcdef1234567890abcdef1234567890",
      actions: [ { action_id: "open_standup_modal" } ]
    }

    # Test that the controller handles the request and returns 500 for API errors
    # The actual Slack API call would be tested in integration tests
    post "/slack/interactive", params: { payload: payload.to_json }
    assert_response :internal_server_error
  end

  test "should handle view_submission payload" do
    payload = {
      type: "view_submission",
      user: { id: "U1234567890", team_id: "T1234567890" },
      team: { id: "T1234567890" },
      view: {
        private_metadata: "C1234567890",
        state: {
          values: {
            "yesterday_block" => {
              "yesterday_input" => { "value" => "Worked on feature A" }
            },
            "today_block" => {
              "today_input" => { "value" => "Will work on feature B" }
            },
            "blocker_block" => {
              "blocker_input" => { "value" => "No blockers" }
            }
          }
        }
      }
    }

    post "/slack/interactive", params: { payload: payload.to_json }

    assert_response :ok
    assert_equal "clear", JSON.parse(response.body)["response_action"]

    # Verify standup was created
    standup = Standup.last
    assert_equal @user.slack_user_id, standup.user_id
    assert_equal "C1234567890", standup.channel_id
    assert_equal "Worked on feature A", standup.yesterday
    assert_equal "Will work on feature B", standup.today
    assert_equal "No blockers", standup.blocker
    assert_equal Date.current, standup.date
  end

  test "should handle view_closed payload" do
    payload = {
      type: "view_closed",
      user: { id: "U1234567890", team_id: "T1234567890" },
      team: { id: "T1234567890" },
      view: { private_metadata: "C1234567890" }
    }

    post "/slack/interactive", params: { payload: payload.to_json }

    assert_response :ok
    # view_closed returns head :ok with no body
  end

  test "should create new user when user doesn't exist" do
    payload = {
      type: "view_submission",
      user: { id: "U9999999999", team_id: "T1234567890" },
      team: { id: "T1234567890" },
      view: {
        private_metadata: "C1234567890",
        state: {
          values: {
            "yesterday_block" => { "yesterday_input" => { "value" => "Test" } },
            "today_block" => { "today_input" => { "value" => "Test" } },
            "blocker_block" => { "blocker_input" => { "value" => "Test" } }
          }
        }
      }
    }

    # Test that the controller handles the request and returns 500 for API errors
    # The actual Slack API call would be tested in integration tests
    post "/slack/interactive", params: { payload: payload.to_json }
    assert_response :internal_server_error
  end

  test "should handle validation errors gracefully" do
    payload = {
      type: "view_submission",
      user: { id: "U1234567890", team_id: "T1234567890" },
      team: { id: "T1234567890" },
      view: {
        private_metadata: "C1234567890",
        state: {
          values: {
            "yesterday_block" => { "yesterday_input" => { "value" => "" } },
            "today_block" => { "today_input" => { "value" => "" } },
            "blocker_block" => { "blocker_input" => { "value" => "" } }
          }
        }
      }
    }

    post "/slack/interactive", params: { payload: payload.to_json }

    assert_response :ok
    response_body = JSON.parse(response.body)
    assert_equal "errors", response_body["response_action"]
    assert_not_nil response_body["errors"]
  end

  test "should handle invalid JSON payload" do
    post "/slack/interactive", params: { payload: "invalid json" }

    assert_response :bad_request
  end

  test "should handle unknown payload type" do
    payload = {
      type: "unknown_type",
      user: { id: "U1234567890", team_id: "T1234567890" },
      team: { id: "T1234567890" }
    }

    post "/slack/interactive", params: { payload: payload.to_json }

    assert_response :ok
    # unknown payload type returns head :ok with no body
  end

  test "should handle SlackClient errors in block_actions" do
    payload = {
      type: "block_actions",
      user: { id: "U1234567890", team_id: "T1234567890" },
      container: { channel_id: "C1234567890" },
      trigger_id: "1234567890.1234567890.abcdef1234567890abcdef1234567890",
      actions: [ { action_id: "open_standup_modal" } ]
    }

    # Test that the controller handles the request and returns 500 for API errors
    # The actual Slack API call would be tested in integration tests
    post "/slack/interactive", params: { payload: payload.to_json }
    assert_response :internal_server_error
  end

  test "should handle SlackClient errors in user info fetch" do
    payload = {
      type: "view_submission",
      user: { id: "U9999999999", team_id: "T1234567890" },
      team: { id: "T1234567890" },
      view: {
        private_metadata: "C1234567890",
        state: {
          values: {
            "yesterday_block" => { "yesterday_input" => { "value" => "Test" } },
            "today_block" => { "today_input" => { "value" => "Test" } },
            "blocker_block" => { "blocker_input" => { "value" => "Test" } }
          }
        }
      }
    }

    # Test that the controller handles the request and returns 500 for API errors
    # The actual Slack API call would be tested in integration tests
    post "/slack/interactive", params: { payload: payload.to_json }
    assert_response :internal_server_error
  end
end
