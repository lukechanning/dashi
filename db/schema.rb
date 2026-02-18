# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_18_182041) do
  create_table "goals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "position"
    t.integer "status", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "goal_id"
    t.integer "position"
    t.integer "status", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["goal_id"], name: "index_projects_on_goal_id"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "todos", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.date "due_date"
    t.text "notes"
    t.integer "position"
    t.integer "project_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["project_id"], name: "index_todos_on_project_id"
    t.index ["user_id", "completed_at"], name: "index_todos_on_user_id_and_completed_at"
    t.index ["user_id", "due_date"], name: "index_todos_on_user_id_and_due_date"
    t.index ["user_id"], name: "index_todos_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "goals", "users"
  add_foreign_key "projects", "goals"
  add_foreign_key "projects", "users"
  add_foreign_key "todos", "projects"
  add_foreign_key "todos", "users"
end
