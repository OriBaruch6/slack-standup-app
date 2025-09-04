
class StandupReminderJob < ApplicationJob
  queue_as :default

  # Posts a message with a button that opens the standup modal when clicked.
  # Params:
  # - channel_id: Slack channel ID to post into (e.g., "C0123456789")
  # - text: Optional override for fallback/plain text
  def perform(channel_id:, text: nil)
    slack = SlackClient.new

    message_texts = build_standup_text
    fallback_txt  = text.presence || message_texts[:fallback]

    blocks = [
      {
        type: "section",
        text: { type: "mrkdwn", text: "*#{message_texts[:headline]}*\n#{message_texts[:prompt]}" }
      },
      {
        type: "actions",
        elements: [
          {
            type: "button",
            text: { type: "plain_text", text: "Open standup" },
            action_id: "open_standup_modal",
            value: "open"
          }
        ]
      }
    ]

    slack.post_message(channel: channel_id, text: fallback_txt, blocks: blocks)
  end
end

private

def build_standup_text
  today     = Date.current
  formatted = today.strftime("%A, %B %-d") 
  headline  = "Good morning :sunny: It's #{formatted}!"
  prompt    = "It's standup time - share yesterday, today, and any blockers."

  { headline: headline, prompt: prompt, fallback: "#{headline} #{prompt}" }
end


