class CreateTodos < ActiveRecord::Migration[8.1]
  def change
    create_table :todos do |t|
      t.string :title
      t.references :project, null: true, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :due_date
      t.datetime :completed_at
      t.integer :position
      t.text :notes

      t.timestamps
    end

    add_index :todos, [ :user_id, :due_date ]
    add_index :todos, [ :user_id, :completed_at ]
  end
end
