# frozen_string_literal: true

# Slack Block Kit structures for the standup app
module SlackBlocks
  # Button action ID for opening the standup modal
  OPEN_STANDUP_ACTION_ID = "open_standup_modal"


  STANDUP_CALLBACK_ID = "standup_submission"


  YESTERDAY_BLOCK_ID = "yesterday_block"
  TODAY_BLOCK_ID = "today_block"
  BLOCKER_BLOCK_ID = "blocker_block"


  YESTERDAY_ACTION_ID = "yesterday_input"
  TODAY_ACTION_ID = "today_input"
  BLOCKER_ACTION_ID = "blocker_input"

  # Build the standup reminder message blocks
  def self.standup_reminder_blocks(headline:, prompt:)
    [
      {
        type: "section",
        text: { type: "mrkdwn", text: "*#{headline}*\n#{prompt}" }
      },
      {
        type: "actions",
        elements: [
          {
            type: "button",
            text: { type: "plain_text", text: "Open standup" },
            action_id: OPEN_STANDUP_ACTION_ID,
            value: "open"
          }
        ]
      }
    ]
  end

  # Build the standup modal view
  def self.standup_modal_view(channel_id: nil)
    # Determine the label for "yesterday" based on current day
    today = Date.current
    yesterday_label = today.monday? ? "On Friday" : "Yesterday"

    {
      type: "modal",
      callback_id: STANDUP_CALLBACK_ID,
      private_metadata: channel_id,
      title: {
        type: "plain_text",
        text: "Daily Standup"
      },
      submit: {
        type: "plain_text",
        text: "Submit"
      },
      close: {
        type: "plain_text",
        text: "Cancel"
      },
      blocks: [
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "Please share your standup updates:"
          }
        },
        {
          type: "input",
          block_id: YESTERDAY_BLOCK_ID,
          element: {
            type: "plain_text_input",
            action_id: YESTERDAY_ACTION_ID,
            multiline: true,
            placeholder: {
              type: "plain_text",
              text: "What did you accomplish #{yesterday_label.downcase}?"
            }
          },
          label: {
            type: "plain_text",
            text: yesterday_label
          }
        },
        {
          type: "input",
          block_id: TODAY_BLOCK_ID,
          element: {
            type: "plain_text_input",
            action_id: TODAY_ACTION_ID,
            multiline: true,
            placeholder: {
              type: "plain_text",
              text: "What are you working on today?"
            }
          },
          label: {
            type: "plain_text",
            text: "Today"
          }
        },
        {
          type: "input",
          block_id: BLOCKER_BLOCK_ID,
          element: {
            type: "plain_text_input",
            action_id: BLOCKER_ACTION_ID,
            multiline: true,
            placeholder: {
              type: "plain_text",
              text: "Any blockers or concerns?"
            }
          },
          label: {
            type: "plain_text",
            text: "Blockers"
          },
          optional: true
        }
      ]
    }
  end
end
