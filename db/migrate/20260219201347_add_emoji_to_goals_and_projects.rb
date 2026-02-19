class AddEmojiToGoalsAndProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :goals, :emoji, :string
    add_column :projects, :emoji, :string
  end
end
