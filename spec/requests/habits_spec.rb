require 'rails_helper'

RSpec.describe "Habits", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /habits" do
    it "lists the user's habits" do
      create(:habit, user: user, title: "Walk the dog")
      get habits_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Walk the dog")
    end
  end

  describe "GET /habits/new" do
    it "renders the new habit form" do
      get new_habit_path
      expect(response).to have_http_status(:ok)
    end

    it "pre-fills the project when project_id is provided" do
      project = create(:project, user: user)
      get new_habit_path(project_id: project.id)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /habits" do
    it "creates a habit" do
      expect {
        post habits_path, params: { habit: { title: "Meditate", frequency: "daily" } }
      }.to change(user.habits, :count).by(1)

      expect(response).to redirect_to(habits_path)
    end

    it "generates today's todo on create" do
      expect {
        post habits_path, params: { habit: { title: "Meditate", frequency: "daily" } }
      }.to change(Todo, :count).by(1)

      expect(Todo.last.habit).to eq(Habit.last)
    end

    it "rejects invalid habits" do
      post habits_path, params: { habit: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /habits/:id" do
    it "updates the habit" do
      habit = create(:habit, user: user)
      patch habit_path(habit), params: { habit: { title: "Updated" } }
      expect(habit.reload.title).to eq("Updated")
    end

    it "does not update another user's habit" do
      other_habit = create(:habit, title: "Other")
      patch habit_path(other_habit), params: { habit: { title: "Hacked" } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /habits/:id" do
    it "destroys the habit and nullifies generated todos" do
      habit = create(:habit, user: user)
      todo = habit.generate_todo_for!(Date.current)

      expect { delete habit_path(habit) }.to change(Habit, :count).by(-1)
      expect(response).to redirect_to(habits_path)
      expect(todo.reload.habit_id).to be_nil
    end
  end

  describe "PATCH /habits/:id/toggle_active" do
    it "pauses an active habit" do
      habit = create(:habit, user: user)
      patch toggle_active_habit_path(habit)
      expect(habit.reload).not_to be_active
    end

    it "resumes a paused habit and generates today's todo" do
      habit = create(:habit, :paused, user: user)
      expect {
        patch toggle_active_habit_path(habit)
      }.to change(Todo, :count).by(1)
      expect(habit.reload).to be_active
    end
  end
end
