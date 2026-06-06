class ScopeHabitTodoUniquenessToKeptTodos < ActiveRecord::Migration[8.1]
  def change
    remove_index :todos, name: "index_todos_on_habit_id_and_due_date"
    add_index :todos, [ :habit_id, :due_date ],
              unique: true,
              where: "deleted_at IS NULL",
              name: "index_todos_on_habit_id_and_due_date"
  end
end
