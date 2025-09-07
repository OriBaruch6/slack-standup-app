class CreateStandups < ActiveRecord::Migration[8.0]
  def change
    create_table :standups do |t|
      t.string :user_id
      t.string :channel_id
      t.string :message_ts
      t.date :date
      t.text :yesterday
      t.text :today
      t.text :blocker

      t.timestamps
    end
  end
end
