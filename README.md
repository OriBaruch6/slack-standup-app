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
<video controls width="100%">
  <source src="video/standup-video.mov" type="video/mp4">
  Your browser does not support the video tag.
</video>

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

## 📚 Additional Resources

- [Slack Block Kit Documentation](https://api.slack.com/block-kit)
- [Slack Interactive Components](https://docs.slack.dev/reference/interaction-payloads)
- [ngrok Documentation](https://ngrok.com/docs)
