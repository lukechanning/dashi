class AddPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :show_stale_banner, :boolean, default: true, null: false
    add_column :users, :show_reflection_banner, :boolean, default: true, null: false
    add_column :users, :stale_threshold_days, :integer, default: 3, null: false
    add_column :users, :week_start_day, :integer, default: 1, null: false
  end
end
