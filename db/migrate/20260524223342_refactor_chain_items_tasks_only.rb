class RefactorChainItemsTasksOnly < ActiveRecord::Migration[8.1]
  def change
    # Add target_project_id — the project a newly-created Todo should belong to
    add_column :chain_items, :target_project_id, :bigint
    add_foreign_key :chain_items, :projects, column: :target_project_id
    add_index :chain_items, :target_project_id, where: "target_project_id IS NOT NULL"

    # Drop project_id — chains are tasks-only; projects as chain steps are removed
    remove_foreign_key :chain_items, column: :project_id
    remove_column :chain_items, :project_id, :bigint

    # Drop columns that were only meaningful for project-type items
    remove_column :chain_items, :item_type, :string
    remove_column :chain_items, :emoji, :string
  end
end
