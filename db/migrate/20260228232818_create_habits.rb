class CreateHabits < ActiveRecord::Migration[8.1]
  def change
    create_table :habits do |t|
      t.string :title, null: false
      t.references :user, null: false, foreign_key: true
      t.references :project, foreign_key: true
      t.integer :frequency, null: false, default: 0
      t.string :days_of_week
      t.boolean :active, null: false, default: true
      t.date :start_date, null: false
      t.integer :position
      t.timestamps
    end

    add_index :habits, [ :user_id, :active ]
  end
end
