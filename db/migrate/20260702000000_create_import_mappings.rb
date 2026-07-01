class CreateImportMappings < ActiveRecord::Migration[8.1]
  def change
    create_table :import_mappings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :source_account_key, null: false
      t.string :record_type, null: false
      t.string :source_id, null: false
      t.string :target_type, null: false
      t.integer :target_id, null: false

      t.timestamps
    end

    add_index :import_mappings,
      [ :user_id, :source_account_key, :record_type, :source_id ],
      unique: true,
      name: "index_import_mappings_on_user_source_and_record"
  end
end
