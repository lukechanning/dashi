class AddAppearanceThemeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :appearance_theme, :string, default: "light", null: false
  end
end
