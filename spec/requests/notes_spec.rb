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
    it "deletes a note" do
      note = create(:note, user: user, notable: goal)
      expect { delete goal_note_path(goal, note) }.to change(Note, :count).by(-1)
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
end
