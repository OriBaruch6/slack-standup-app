# Slack Standup App

A Ruby on Rails application that automates daily standup meetings in Slack. The app sends daily reminders to team channels and provides an interactive modal for team members to submit their standup updates.

## 🚀 Quick Start

### Prerequisites
- Ruby 3.3.4+
- Rails 8.0+
- Slack App with Bot Token
- ngrok (for local development)

### 1. Local Development Setup

#### Install Dependencies
```bash
# Install Ruby dependencies
bundle install

# Create and setup database
bin/rails db:create
bin/rails db:migrate
```

#### Environment Variables
Create a `.env` file in the project root:
```bash
SLACK_BOT_TOKEN=xoxb-your-bot-token-here
SLACK_SIGNING_SECRET=your-signing-secret-here
```

#### Start the Rails Server
```bash
bin/rails server
```
Your app will be running at `http://localhost:3000`

### 2. Expose Local Server with ngrok

Since Slack needs to send webhooks to your local app, you'll need to expose it to the internet using ngrok.

#### Install ngrok
```bash
# Using Homebrew (macOS)
brew install ngrok

# Or download from https://ngrok.com/download
```

#### Start ngrok
```bash
# Expose your local Rails server
ngrok http 3000
```

You'll see output like:
```
Session Status                online
Account                       your-account
Version                       3.x.x
Region                        United States (us)
Latency                       -
Web Interface                 http://127.0.0.1:4040
Forwarding                    https://abc123def456.ngrok-free.app -> http://localhost:3000
```

**Copy the HTTPS URL** (e.g., `https://abc123def456.ngrok-free.app`) - you'll need this for Slack configuration.

### 3. Configure Slack App

#### Update Request URL
1. Go to your [Slack App Dashboard](https://api.slack.com/apps)
2. Navigate to **Interactivity & Shortcuts**
3. Set **Request URL** to: `https://your-ngrok-url.ngrok-free.app/slack/interactive`
4. Save changes

#### Required Bot Token Scopes
Make sure your Slack app has these scopes:
- `chat:write` - Post messages to channels
- `channels:read` - Read channel information
- `users:read` - Read user information

#### Invite Bot to Channel
In your Slack workspace, invite the bot to the channel where you want standup reminders:
```
/invite @YourBotName
```

### 4. Test the Flow

#### Send a Test Standup Reminder
```bash
# In Rails console
bin/rails console

# Send a test reminder to your channel
StandupReminderJob.perform_now(channel_id: "C09DJNCLTU6")
```

#### Expected Flow
1. **Message appears** in the channel with an "Open standup" button
2. **Click the button** - a modal opens with the standup form
3. **Fill out the form** and submit
4. **Standup data is saved** to the database

#### Demo Video
![Standup Demo](video/standup-demo.gif)

## 🏗️ Architecture

![Architecture](docs/architecture.png)

### Core Components

- **StandupReminderJob**: Sends daily reminders to Slack channels
- **SlackController**: Handles interactive components (buttons, modals)
- **SlackClient**: Wrapper for Slack Web API calls
- **Models**: User, Team, Standup, StandupReminder for data persistence

### Database Schema

- **Users**: Slack user information and team association
- **Teams**: Slack workspace/team data
- **Standups**: Daily standup submissions (yesterday, today, blockers)
- **StandupReminders**: Records of sent reminder messages

## 🔄 Slack Interactive Flow

The app implements a complete interactive flow using Slack's Block Kit and interactive components.

### Step-by-Step Flow

#### 1. Daily Reminder Posted
- **Job runs**: `StandupReminderJob` posts a message with an "Open standup" button
- **Working days only**: Job automatically skips weekends (Saturday/Sunday)
- **Slack API**: `chat.postMessage` with Block Kit button
- **User sees**: Message in channel with clickable button

![Open Standup Button](docs/open-standup.png)

#### 2. User Clicks Button
- **Slack sends**: `POST /slack/interactive` with `type: "block_actions"`
- **Contains**: `trigger_id` (short-lived, expires quickly)
- **App responds**: Immediately calls `views.open` to show modal

#### 3. Modal Opens
- **Slack API**: `views.open` using the `trigger_id`
- **User sees**: Standup form modal with fields for yesterday, today, and blockers
- **Smart labeling**: On Mondays, "Yesterday" field shows "Friday" instead

![Standup Modal](docs/standup-modal.png)

#### 4. User Submits Form
- **Slack sends**: `POST /slack/interactive` with `type: "view_submission"`
- **Contains**: Form data in `view.state.values`
- **App processes**: Saves standup to database
- **App responds**: `{ "response_action": "clear" }` to close modal
- **Alternative**: User can close modal without submitting (`type: "view_closed"`)

### Endpoint Details

**POST `/slack/interactive`**
- Handles three payload types:
  - `block_actions`: Button clicks → opens modal
  - `view_submission`: Form submissions → saves data
  - `view_closed`: Modal closed without submitting → logs event

### Data Flow

```
Job → Slack Message → User Click → Modal → Form Submit → Database
```

## 📋 API Requests & Responses

### Outgoing Requests (App → Slack)

#### 1. `chat.postMessage` - Send Standup Reminder
**Endpoint:** `POST https://slack.com/api/chat.postMessage`

**Request Payload:**
```json
{
  "channel": "C09DJNCLTU6",
  "text": "It's standup time - share yesterday, today, and any blockers.",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "It's standup time - share yesterday, today, and any blockers."
      }
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "Open standup"
          },
          "action_id": "open_standup_modal"
        }
      ]
    }
  ]
}
```

**Response:**
```json
{
  "ok": true,
  "channel": "C09DJNCLTU6",
  "ts": "1234567890.123456",
  "message": {
    "type": "message",
    "subtype": null,
    "text": "It's standup time - share yesterday, today, and any blockers.",
    "ts": "1234567890.123456",
    "username": "standup-bot",
    "bot_id": "B1234567890"
  }
}
```

#### 2. `users.info` - Get User Information
**Endpoint:** `POST https://slack.com/api/users.info`

**Request Payload:**
```json
{
  "user": "U012A3CDE"
}
```

**Response:**
```json
{
  "ok": true,
  "user": {
    "id": "U012A3CDE",
    "team_id": "T012AB3C4",
    "name": "spengler",
    "deleted": false,
    "color": "9f69e7",
    "real_name": "Egon Spengler",
    "tz": "America/Los_Angeles",
    "tz_label": "Pacific Daylight Time",
    "tz_offset": -25200,
    "profile": {
      "avatar_hash": "ge3b51ca72de",
      "status_text": "Print is dead",
      "status_emoji": ":books:",
      "real_name": "Egon Spengler",
      "display_name": "spengler",
      "first_name": "Egon",
      "last_name": "Spengler",
      "image_24": "https://...",
      "image_32": "https://...",
      "image_48": "https://...",
      "image_72": "https://...",
      "image_192": "https://...",
      "image_512": "https://..."
    }
  }
}
```

#### 3. `views.open` - Open Standup Modal
**Endpoint:** `POST https://slack.com/api/views.open`

**Request Payload:**
```json
{
  "trigger_id": "1234567890.1234567890.abcdef1234567890abcdef1234567890",
  "view": {
    "type": "modal",
    "callback_id": "standup_modal",
    "title": {
      "type": "plain_text",
      "text": "Daily Standup"
    },
    "submit": {
      "type": "plain_text",
      "text": "Submit"
    },
    "close": {
      "type": "plain_text",
      "text": "Cancel"
    },
    "private_metadata": "C09DJNCLTU6",
    "blocks": [
      {
        "type": "input",
        "block_id": "yesterday_block",
        "element": {
          "type": "plain_text_input",
          "action_id": "yesterday_input",
          "multiline": true,
          "placeholder": {
            "type": "plain_text",
            "text": "What did you accomplish yesterday?"
          }
        },
        "label": {
          "type": "plain_text",
          "text": "Yesterday"
        }
      },
      {
        "type": "input",
        "block_id": "today_block",
        "element": {
          "type": "plain_text_input",
          "action_id": "today_input",
          "multiline": true,
          "placeholder": {
            "type": "plain_text",
            "text": "What will you work on today?"
          }
        },
        "label": {
          "type": "plain_text",
          "text": "Today"
        }
      },
      {
        "type": "input",
        "block_id": "blocker_block",
        "element": {
          "type": "plain_text_input",
          "action_id": "blocker_input",
          "multiline": true,
          "placeholder": {
            "type": "plain_text",
            "text": "Any blockers or concerns?"
          }
        },
        "label": {
          "type": "plain_text",
          "text": "Blockers"
        },
        "optional": true
      }
    ]
  }
}
```

**Response:**
```json
{
  "ok": true,
  "view": {
    "id": "V1234567890",
    "team_id": "T012AB3C4",
    "type": "modal",
    "title": {
      "type": "plain_text",
      "text": "Daily Standup"
    },
    "submit": {
      "type": "plain_text",
      "text": "Submit"
    },
    "close": {
      "type": "plain_text",
      "text": "Cancel"
    },
    "blocks": [...],
    "private_metadata": "C09DJNCLTU6",
    "callback_id": "standup_modal",
    "state": {
      "values": {}
    },
    "hash": "1234567890.abcdef",
    "clear_on_close": false,
    "notify_on_close": false,
    "root_view_id": "V1234567890",
    "app_id": "A1234567890",
    "external_id": "",
    "app_installed_team_id": "T012AB3C4",
    "bot_id": "B1234567890"
  }
}
```

### Incoming Requests (Slack → App)

#### 1. `block_actions` - Button Click
**Endpoint:** `POST /slack/interactive`

**Request Payload:**
```json
{
  "type": "block_actions",
  "user": {
    "id": "U012A3CDE",
    "username": "spengler",
    "name": "spengler",
    "team_id": "T012AB3C4"
  },
  "api_app_id": "A1234567890",
  "token": "verification_token",
  "container": {
    "type": "message",
    "message_ts": "1234567890.123456",
    "channel_id": "C09DJNCLTU6",
    "is_ephemeral": false
  },
  "trigger_id": "1234567890.1234567890.abcdef1234567890abcdef1234567890",
  "team": {
    "id": "T012AB3C4",
    "domain": "example"
  },
  "channel": {
    "id": "C09DJNCLTU6",
    "name": "general"
  },
  "response_url": "https://hooks.slack.com/actions/T012AB3C4/1234567890/abcdef1234567890abcdef1234567890",
  "actions": [
    {
      "action_id": "open_standup_modal",
      "block_id": "action_block",
      "text": {
        "type": "plain_text",
        "text": "Open standup",
        "emoji": true
      },
      "value": "click_me_123",
      "type": "button",
      "action_ts": "1234567890.123456"
    }
  ]
}
```

#### 2. `view_submission` - Modal Form Submit
**Endpoint:** `POST /slack/interactive`

**Request Payload:**
```json
{
  "type": "view_submission",
  "team": {
    "id": "T012AB3C4",
    "domain": "example"
  },
  "user": {
    "id": "U012A3CDE",
    "username": "spengler",
    "name": "spengler",
    "team_id": "T012AB3C4"
  },
  "api_app_id": "A1234567890",
  "token": "verification_token",
  "trigger_id": "1234567890.1234567890.abcdef1234567890abcdef1234567890",
  "view": {
    "id": "V1234567890",
    "team_id": "T012AB3C4",
    "type": "modal",
    "blocks": [...],
    "private_metadata": "C09DJNCLTU6",
    "callback_id": "standup_modal",
    "state": {
      "values": {
        "yesterday_block": {
          "yesterday_input": {
            "type": "plain_text_input",
            "value": "Worked on the new feature implementation"
          }
        },
        "today_block": {
          "today_input": {
            "type": "plain_text_input",
            "value": "Will continue with testing and documentation"
          }
        },
        "blocker_block": {
          "blocker_input": {
            "type": "plain_text_input",
            "value": "Waiting for design approval"
          }
        }
      }
    },
    "hash": "1234567890.abcdef",
    "title": {
      "type": "plain_text",
      "text": "Daily Standup"
    },
    "clear_on_close": false,
    "notify_on_close": false,
    "close": {
      "type": "plain_text",
      "text": "Cancel"
    },
    "submit": {
      "type": "plain_text",
      "text": "Submit"
    },
    "previous_view_id": null,
    "root_view_id": "V1234567890",
    "app_id": "A1234567890",
    "external_id": "",
    "app_installed_team_id": "T012AB3C4",
    "bot_id": "B1234567890"
  },
  "response_urls": []
}
```

**Expected Response:**
```json
{
  "response_action": "clear"
}
```

#### 3. `view_closed` - Modal Closed
**Endpoint:** `POST /slack/interactive`

**Request Payload:**
```json
{
  "type": "view_closed",
  "team": {
    "id": "T012AB3C4",
    "domain": "example"
  },
  "user": {
    "id": "U012A3CDE",
    "username": "spengler",
    "name": "spengler",
    "team_id": "T012AB3C4"
  },
  "api_app_id": "A1234567890",
  "token": "verification_token",
  "view": {
    "id": "V1234567890",
    "team_id": "T012AB3C4",
    "type": "modal",
    "private_metadata": "C09DJNCLTU6",
    "callback_id": "standup_modal",
    "state": {
      "values": {}
    },
    "hash": "1234567890.abcdef",
    "title": {
      "type": "plain_text",
      "text": "Daily Standup"
    },
    "clear_on_close": false,
    "notify_on_close": false,
    "close": {
      "type": "plain_text",
      "text": "Cancel"
    },
    "submit": {
      "type": "plain_text",
      "text": "Submit"
    },
    "previous_view_id": null,
    "root_view_id": "V1234567890",
    "app_id": "A1234567890",
    "external_id": "",
    "app_installed_team_id": "T012AB3C4",
    "bot_id": "B1234567890"
  },
  "is_cleared": false
}
```

**Expected Response:**
```json
{
  "response_action": "clear"
}
```

## Phase 2: Observability and Intelligence

In the next phase, I would focus on production readiness with better visibility and smarter insights.

- Monitoring and Metrics (Prometheus + Grafana):
  - Export key app metrics (jobs executed, Slack API success/error rates, request latencies, DB writes) via a Prometheus endpoint.
  - Build Grafana dashboards for team-level adoption and operational health.

- Intelligent Evaluation (MCP + AI Model):
  - Deploy an MCP powered AI evaluator to analyze standup usage and patterns.
  - Provide insights into team engagement, blockers frequency, and trends over time to improve effectiveness.

- Structured Application Logs:
  - All logs will follow the format: [FileName] - [methodName] - message.
    - Example: [SlackController] - [handle_view_submission] - Standup created
  - This makes it easy to correlate logs, traces, and metrics across the system.

## 📚 Additional Resources

- [Slack Block Kit Documentation](https://api.slack.com/block-kit)
- [Slack Interactive Components](https://docs.slack.dev/reference/interaction-payloads)
- [Slack users.info API Reference](https://docs.slack.dev/reference/methods/users.info/)
- [Slack chat.postMessage API Reference](https://docs.slack.dev/reference/methods/chat.postMessage/)
- [ngrok Documentation](https://ngrok.com/docs)
