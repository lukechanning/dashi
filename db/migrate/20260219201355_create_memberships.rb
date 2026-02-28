class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :memberable, polymorphic: true, null: false
      t.integer :role, default: 0, null: false

      t.timestamps
    end

    add_index :memberships, [ :user_id, :memberable_type, :memberable_id ], unique: true, name: "index_memberships_on_user_and_memberable"
  end
end
