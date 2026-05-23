class CreateChainItems < ActiveRecord::Migration[8.1]
  def change
    create_table :chain_items do |t|
      t.references :chain, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :title, null: false
      t.text :description
      t.string :emoji
      t.string :item_type, null: false
      t.bigint :todo_id
      t.bigint :project_id
      t.datetime :completed_at

      t.timestamps
    end

    add_index :chain_items, [ :chain_id, :position ], unique: true
    add_index :chain_items, :todo_id, where: "todo_id IS NOT NULL"
    add_index :chain_items, :project_id, where: "project_id IS NOT NULL"
    add_foreign_key :chain_items, :todos, column: :todo_id
    add_foreign_key :chain_items, :projects, column: :project_id
  end
end
