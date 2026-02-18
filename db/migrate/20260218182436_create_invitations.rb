class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.string :email
      t.string :token
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.datetime :accepted_at

      t.timestamps
    end
    add_index :invitations, :token, unique: true
  end
end
