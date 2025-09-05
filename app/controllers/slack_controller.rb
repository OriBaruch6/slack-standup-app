
class SlackController < ApplicationController

  # Handle Slack interactive components (buttons, modals, etc.)
  def interactive
    payload = JSON.parse(params[:payload])
    payload_type = payload["type"]

    case payload_type
    when "block_actions"
      handle_block_actions(payload)
    when "view_submission"
      handle_view_submission(payload)
    when "view_closed"
      handle_view_closed(payload)
    else
      Rails.logger.warn "Unknown payload type: #{payload_type}"
      head :ok
    end
  end

  private

  # Handle button clicks - open the standup modal
  def handle_block_actions(payload)
    trigger_id = payload["trigger_id"]
    user_id = payload["user"]["id"]
    channel_id = payload["channel"]["id"]

    slack_client = SlackClient.new
    modal_view = build_standup_modal(user_id, channel_id)
    
    slack_client.open_modal(trigger_id: trigger_id, view: modal_view)
    
    head :ok
  end

  # Handle modal submission - save the standup
  def handle_view_submission(payload)
    view_state = payload["view"]["state"]["values"]
    user_id = payload["user"]["id"]
    channel_id = payload["channel"]["id"]

    # Extract form values
    standup_data = extract_standup_data(view_state, user_id, channel_id)
    
    Rails.logger.info "Standup submitted: #{standup_data}"
    
    # Return ack
    render json: { response_action: "clear" }
  end

  # Handle modal closed
  def handle_view_closed(payload)
    Rails.logger.info "Modal closed by user: #{payload["user"]["id"]}"
    head :ok
  end

  # Build the standup modal view
  def build_standup_modal(user_id, channel_id)
    SlackBlocks.standup_modal_view
  end

  # Extract standup data from form submission
  def extract_standup_data(view_state, user_id, channel_id)
    {
      user_id: user_id,
      channel_id: channel_id,
      date: Date.current,
      yesterday: view_state.dig(SlackBlocks::YESTERDAY_BLOCK_ID, SlackBlocks::YESTERDAY_ACTION_ID, "value"),
      today: view_state.dig(SlackBlocks::TODAY_BLOCK_ID, SlackBlocks::TODAY_ACTION_ID, "value"),
      blocker: view_state.dig(SlackBlocks::BLOCKER_BLOCK_ID, SlackBlocks::BLOCKER_ACTION_ID, "value")
    }
  end

end
