class CreateChains < ActiveRecord::Migration[8.1]
  def change
    create_table :chains do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :emoji
      t.datetime :completed_at

      t.timestamps
    end
  end
end
