class CreateStandupReminders < ActiveRecord::Migration[8.0]
  def change
    create_table :standup_reminders do |t|
      t.string :channel_id
      t.string :message_ts
      t.datetime :posted_at

      t.timestamps
    end
  end
end
