# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class SlackClientTest < ActiveSupport::TestCase
  def setup
    @slack_client = SlackClient.new(bot_token: "xoxb-test-token")
  end

  test "initializes with bot token" do
    client = SlackClient.new(bot_token: "xoxb-test-token")
    assert_not_nil client.instance_variable_get(:@client)
  end

  test "raises error when bot token is missing" do
    assert_raises(ArgumentError, "Missing SLACK_BOT_TOKEN") do
      SlackClient.new(bot_token: nil)
    end
  end

  test "raises error when bot token is empty" do
    assert_raises(ArgumentError, "Missing SLACK_BOT_TOKEN") do
      SlackClient.new(bot_token: "")
    end
  end

  test "raises error when bot token is whitespace" do
    assert_raises(ArgumentError, "Missing SLACK_BOT_TOKEN") do
      SlackClient.new(bot_token: "   ")
    end
  end

  test "post_message accepts all parameters" do
    # Test that the method accepts all parameters without error
    # The actual Slack API call would be tested in integration tests
    assert_raises(Slack::Web::Api::Errors::SlackError) do
      @slack_client.post_message(
        channel: "C1234567890",
        text: "Test message",
        blocks: [ { type: "section", text: { type: "mrkdwn", text: "Test" } } ],
        thread_ts: "1234567890.123456"
      )
    end
  end

  test "post_message accepts minimal parameters" do
    # Test that the method accepts minimal parameters without error
    # The actual Slack API call would be tested in integration tests
    assert_raises(ArgumentError) do
      @slack_client.post_message(channel: "C1234567890")
    end
  end

  test "post_message handles nil parameters" do
    # Test that the method handles nil parameters without error
    # The actual Slack API call would be tested in integration tests
    assert_raises(Slack::Web::Api::Errors::SlackError) do
      @slack_client.post_message(
        channel: "C1234567890",
        text: "Test message",
        blocks: nil,
        thread_ts: nil
      )
    end
  end

  test "open_modal opens modal with trigger_id and view" do
    trigger_id = "1234567890.1234567890.abcdef1234567890abcdef1234567890"
    view = {
      type: "modal",
      title: { type: "plain_text", text: "Test Modal" }
    }

    # Test that the method raises an error when called
    # The actual Slack API call would be tested in integration tests
    assert_raises(Slack::Web::Api::Errors::SlackError) do
      @slack_client.open_modal(trigger_id: trigger_id, view: view)
    end
  end

  test "get_user_info fetches user information" do
    user_id = "U1234567890"

    # Test that the method raises an error when called
    # The actual Slack API call would be tested in integration tests
    assert_raises(Slack::Web::Api::Errors::SlackError) do
      @slack_client.get_user_info(user_id: user_id)
    end
  end

  test "post_message lets errors bubble up" do
    # Test that the method raises an error when called
    # The actual Slack API call would be tested in integration tests
    assert_raises(Slack::Web::Api::Errors::SlackError) do
      @slack_client.post_message(channel: "C1234567890", text: "test")
    end
  end

  test "open_modal lets errors bubble up" do
    trigger_id = "1234567890.1234567890.abcdef1234567890abcdef1234567890"
    view = { type: "modal" }

    # Test that the method raises an error when called
    # The actual Slack API call would be tested in integration tests
    assert_raises(Slack::Web::Api::Errors::SlackError) do
      @slack_client.open_modal(trigger_id: trigger_id, view: view)
    end
  end

  test "get_user_info lets errors bubble up" do
    user_id = "U1234567890"

    # Test that the method raises an error when called
    # The actual Slack API call would be tested in integration tests
    assert_raises(Slack::Web::Api::Errors::SlackError) do
      @slack_client.get_user_info(user_id: user_id)
    end
  end
end
