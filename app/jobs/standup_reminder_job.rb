
class StandupReminderJob < ApplicationJob
  queue_as :default

  # Posts a message with a button that opens the standup modal when clicked.
  # Only runs on working days (Monday-Friday), skips weekends.
  # Params:
  # - channel_id: Slack channel ID to post into (e.g., "C0123456789")
  # - text: Optional override for fallback/plain text
  def perform(channel_id:, text: nil)
    # Skip if it's weekend (Saturday = 6, Sunday = 0)
   # today = Date.current
   # if today.saturday? || today.sunday?
    # Rails.logger.info "Skipping standup reminder on weekend: #{today.strftime('%A')}"
     # return
    #end

    slack = SlackClient.new

    message_texts = build_standup_text
    fallback_txt  = text.presence || message_texts[:fallback]
    blocks = SlackBlocks.standup_reminder_blocks(
      headline: message_texts[:headline],
      prompt: message_texts[:prompt]
    )

    # Post the message to Slack
    begin
      response = slack.post_message(channel: channel_id, text: fallback_txt, blocks: blocks)

      # Create a StandupReminder record
      StandupReminder.create!(
        channel_id: channel_id,
        message_ts: response["ts"],
        posted_at: Time.current
      )
      Rails.logger.info "Standup reminder posted and recorded: #{response["ts"]}"
    rescue SlackApiError => e
      Rails.logger.error "Failed to post standup reminder: #{e.message}"
      raise e
    end
  end
end

private

def build_standup_text
  today     = Date.current
  formatted = today.strftime("%A, %B %-d")
  headline  = "Good morning :sunny: It's #{formatted}!"
  prompt = today.monday? ? "It's standup time - share Friday, today, and any blockers." : "It's standup time - share yesterday, today, and any blockers."

  { headline: headline, prompt: prompt, fallback: "#{headline} #{prompt}" }
end
