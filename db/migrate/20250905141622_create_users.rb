class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :slack_user_id
      t.string :slack_user_team
      t.string :display_name
      t.string :real_name

      t.timestamps
    end
  end
end
