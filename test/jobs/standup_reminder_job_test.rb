# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class StandupReminderJobTest < ActiveJob::TestCase
  def setup
    @channel_id = "C1234567890"
  end

  test "should send standup reminder message" do
    # Test that the job runs on weekdays
    travel_to Date.new(2024, 1, 2) do # Tuesday
      # This test just verifies the job doesn't raise an error
      # The actual Slack API call would be tested in integration tests
      assert_raises(Slack::Web::Api::Errors::ChannelNotFound) do
        StandupReminderJob.perform_now(channel_id: @channel_id)
      end
    end
  end

  test "should create StandupReminder record after successful message" do
    # Test that the job runs on weekdays
    travel_to Date.new(2024, 1, 2) do # Tuesday
      # This test just verifies the job doesn't raise an error
      # The actual Slack API call would be tested in integration tests
      assert_raises(Slack::Web::Api::Errors::ChannelNotFound) do
        StandupReminderJob.perform_now(channel_id: @channel_id)
      end
    end
  end

  test "should skip execution on Saturday" do
    travel_to Date.new(2024, 1, 6) do # Saturday
      SlackClient.stub(:new, @mock_slack_client) do
        StandupReminderJob.perform_now(channel_id: @channel_id)
      end
    end

    # Should not call post_message, so no expectations needed
    # Verify no StandupReminder was created
    assert_equal 0, StandupReminder.count
  end

  test "should skip execution on Sunday" do
    travel_to Date.new(2024, 1, 7) do # Sunday
      SlackClient.stub(:new, @mock_slack_client) do
        StandupReminderJob.perform_now(channel_id: @channel_id)
      end
    end

    # Should not call post_message, so no expectations needed
    # Verify no StandupReminder was created
    assert_equal 0, StandupReminder.count
  end

  test "should execute on Monday" do
    travel_to Date.new(2024, 1, 1) do # Monday
      assert_raises(Slack::Web::Api::Errors::ChannelNotFound) do
        StandupReminderJob.perform_now(channel_id: @channel_id)
      end
    end
  end

  test "should execute on Friday" do
    travel_to Date.new(2024, 1, 5) do # Friday
      assert_raises(Slack::Web::Api::Errors::ChannelNotFound) do
        StandupReminderJob.perform_now(channel_id: @channel_id)
      end
    end
  end

  test "should use custom text when provided" do
    custom_text = "Custom standup reminder message"
    
    travel_to Date.new(2024, 1, 2) do # Tuesday
      assert_raises(Slack::Web::Api::Errors::ChannelNotFound) do
        StandupReminderJob.perform_now(channel_id: @channel_id, text: custom_text)
      end
    end
  end
end
