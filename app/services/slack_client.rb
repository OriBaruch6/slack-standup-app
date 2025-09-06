
require "slack-ruby-client"

# Custom error class for Slack API errors
class SlackApiError < StandardError
end

#  Slack Web API used by jobs and controllers.
class SlackClient
  def initialize(bot_token: ENV["SLACK_BOT_TOKEN"])
    raise ArgumentError, "Missing SLACK_BOT_TOKEN" if bot_token.to_s.strip.empty?

    @client = Slack::Web::Client.new(token: bot_token)
  end

  # Sends a message to a Slack channel using POST method /api/chat.postMessage.
  # Provide the initial payload of the request.
  # Returns the Slack API response hash.
  def post_message(channel:, text: nil, blocks: nil, thread_ts: nil)
    payload = { channel: channel }
    payload[:text] = text if text
    payload[:blocks] = blocks if blocks
    payload[:thread_ts] = thread_ts if thread_ts

    @client.chat_postMessage(payload)
  end

  # Opens a Standup modal using POST method /api/views.open
  # Params:
  # - trigger_id: Short-lived ID from block_actions payload
  # - view: Modal view definition hash
  # Returns the Slack API response hash.
  def open_modal(trigger_id:, view:)
    @client.views_open(trigger_id: trigger_id, view: view)
  end

  # Gets user information from Slack using POST method /api/users.info
  # Params:
  # - user_id: Slack user ID
  # Returns the Slack API response hash with user details.
  def get_user_info(user_id:)
    @client.users_info(user: user_id)
  end
end
