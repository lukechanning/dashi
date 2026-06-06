class AddDeletedAtToCoreContent < ActiveRecord::Migration[8.1]
  def change
    add_column :chains, :deleted_at, :datetime
    add_column :goals, :deleted_at, :datetime
    add_column :habits, :deleted_at, :datetime
    add_column :notes, :deleted_at, :datetime
    add_column :projects, :deleted_at, :datetime
    add_column :todos, :deleted_at, :datetime

    add_index :chains, :deleted_at
    add_index :goals, :deleted_at
    add_index :habits, :deleted_at
    add_index :notes, :deleted_at
    add_index :projects, :deleted_at
    add_index :todos, :deleted_at
  end
end
