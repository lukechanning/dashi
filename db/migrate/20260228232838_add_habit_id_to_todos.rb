class AddHabitIdToTodos < ActiveRecord::Migration[8.1]
  def change
    add_reference :todos, :habit, foreign_key: true
    add_index :todos, [ :habit_id, :due_date ], unique: true
  end
end
