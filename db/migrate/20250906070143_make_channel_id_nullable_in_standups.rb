class MakeChannelIdNullableInStandups < ActiveRecord::Migration[8.0]
  def change
    change_column_null :standups, :channel_id, true
  end
end
