
class SlackController < ApplicationController
  # Skip CSRF protection for Slack webhooks
  skip_before_action :verify_authenticity_token, only: [ :interactive ]

  # Handle Slack interactive components (buttons, modals, etc.)
  def interactive
    begin
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
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON payload: #{e.message}"
      head :bad_request
    rescue Slack::Web::Api::Errors::SlackError => e
      Rails.logger.error "Slack API error: #{e.message}"
      head :internal_server_error
    end
  end

  private

  # Handle button clicks - open the standup modal
  def handle_block_actions(payload)
    trigger_id = payload["trigger_id"]
    channel_id = payload["container"]["channel_id"]

    begin
      slack_client = SlackClient.new
      modal_view = SlackBlocks.standup_modal_view(channel_id: channel_id)

      slack_client.open_modal(trigger_id: trigger_id, view: modal_view)
      head :ok
    rescue SlackApiError => e
      Rails.logger.error "Failed to open modal: #{e.message}"
      head :internal_server_error
    end
  end

  # Handle modal submission - save the standup
  def handle_view_submission(payload)
      view_state = payload["view"]["state"]["values"]
      user_id = payload["user"]["id"]
      team_id = payload["team"]["id"]
      channel_id = payload["view"]["private_metadata"]

      # Extract form values
      standup_data = extract_standup_data(view_state, user_id, channel_id)

      # Find or create user
      user = find_or_create_user(user_id, team_id)

      # Save standup
      standup = Standup.create!(
        user_id: user_id,
        channel_id: channel_id,
        date: standup_data[:date],
        yesterday: standup_data[:yesterday],
        today: standup_data[:today],
        blocker: standup_data[:blocker]
      )

      Rails.logger.info "Standup saved: #{standup.id}"

      # Return ack
      render json: { response_action: "clear" }
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Validation error saving standup: #{e.message}"
    render json: {
      response_action: "errors",
      errors: {
        "yesterday_block": "Please check your input and try again",
        "today_block": "Please check your input and try again",
        "blocker_block": "Please check your input and try again"
      }
    }
  end

  # Handle modal closed
  def handle_view_closed(payload)
    Rails.logger.info "Modal closed by user: #{payload["user"]["id"]}"
    head :ok
  end

  # Extract standup data from form submission
  def extract_standup_data(view_state, user_id, channel_id)
    {
      user_id: user_id,
      channel_id: channel_id || nil,
      date: Date.current,
      yesterday: view_state.dig(SlackBlocks::YESTERDAY_BLOCK_ID, SlackBlocks::YESTERDAY_ACTION_ID, "value"),
      today: view_state.dig(SlackBlocks::TODAY_BLOCK_ID, SlackBlocks::TODAY_ACTION_ID, "value"),
      blocker: view_state.dig(SlackBlocks::BLOCKER_BLOCK_ID, SlackBlocks::BLOCKER_ACTION_ID, "value")
    }
  end

  # Find or create user from Slack payload
  def find_or_create_user(user_id, team_id)
    user = User.find_by(slack_user_id: user_id)

    unless user
      # Find or create team first
      team = Team.find_or_create_by(slack_user_team: team_id)

      # Get real user info from Slack
      begin
        slack_client = SlackClient.new
        user_info_response = slack_client.get_user_info(user_id: user_id)
        user_info = user_info_response["user"]

        # Extract names
        display_name = user_info.dig("profile", "display_name") ||
                      user_info["real_name"] ||
                      user_info["name"]

        real_name = user_info["real_name"] ||
                   user_info["name"]
      rescue SlackApiError => e
        Rails.logger.warn "Failed to get user info for #{user_id}: #{e.message}"
      end

      # User Creation
      user = User.create!(
        slack_user_id: user_id,
        slack_user_team: team_id,
        display_name: display_name,
        real_name: real_name
      )
    end

    user
  end
end
