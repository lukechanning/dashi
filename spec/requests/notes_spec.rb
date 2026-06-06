require 'rails_helper'

RSpec.describe "Notes", type: :request do
  let(:user) { create(:user) }
  let(:goal) { create(:goal, user: user) }

  before { sign_in(user) }

  describe "POST /goals/:goal_id/notes" do
    it "creates a note on a goal" do
      expect {
        post goal_notes_path(goal), params: { note: { body: "Making progress!" } }
      }.to change(goal.notes, :count).by(1)
    end

    it "rejects blank notes" do
      post goal_notes_path(goal), params: { note: { body: "" } }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "PATCH /goals/:goal_id/notes/:id" do
    it "updates a note" do
      note = create(:note, user: user, notable: goal, body: "Old")
      patch goal_note_path(goal, note), params: { note: { body: "Updated" } }
      expect(note.reload.body).to eq("Updated")
    end
  end

  describe "DELETE /goals/:goal_id/notes/:id" do
    it "soft-deletes a note" do
      note = create(:note, user: user, notable: goal)
      expect { delete goal_note_path(goal, note) }.not_to change(Note.unscoped, :count)
      expect(note.reload.deleted_at).to be_present
    end
  end

  describe "notes on other resources" do
    it "creates a note on a project" do
      project = create(:project, user: user)
      expect {
        post project_notes_path(project), params: { note: { body: "Project note" } }
      }.to change(project.notes, :count).by(1)
    end

    it "creates a note on a daily page" do
      daily_page = create(:daily_page, user: user)
      expect {
        post daily_page_notes_path(daily_page), params: { note: { body: "Journal entry" } }
      }.to change(daily_page.notes, :count).by(1)
    end
  end

  describe "GET /notes" do
    it "returns 200" do
      get notes_index_path
      expect(response).to have_http_status(:ok)
    end

    it "shows notes from daily pages" do
      daily_page = create(:daily_page, user: user)
      create(:note, user: user, notable: daily_page, body: "Today I learned something important")
      get notes_index_path
      expect(response.body).to include("Today I learned something important")
    end

    it "shows notes from goals" do
      create(:note, user: user, notable: goal, body: "Goal note here")
      get notes_index_path
      expect(response.body).to include("Goal note here")
    end

    it "shows notes from todos" do
      todo = create(:todo, user: user)
      create(:note, user: user, notable: todo, body: "Todo note here")
      get notes_index_path
      expect(response.body).to include("Todo note here")
    end

    it "shows the notable source context for each note" do
      create(:note, user: user, notable: goal, body: "Source check")
      get notes_index_path
      expect(response.body).to include(goal.title)
    end

    it "does not show notes belonging to other users" do
      other = create(:user)
      other_goal = create(:goal, user: other)
      create(:note, user: other, notable: other_goal, body: "Private note")
      get notes_index_path
      expect(response.body).not_to include("Private note")
    end

    it "shows an empty state when the user has no notes" do
      get notes_index_path
      expect(response.body).to include("No notes yet")
    end
  end
end
