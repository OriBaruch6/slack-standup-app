class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :slack_user_team

      t.timestamps
    end
  end
end
