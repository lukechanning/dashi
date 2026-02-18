class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :title
      t.text :description
      t.references :goal, null: true, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.integer :position

      t.timestamps
    end
  end
end
