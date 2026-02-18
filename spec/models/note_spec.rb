require 'rails_helper'

RSpec.describe Note, type: :model do
  describe "associations" do
    it { should belong_to(:notable) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:body) }
  end

  describe "scopes" do
    it "orders by most recent first" do
      user = create(:user)
      goal = create(:goal, user: user)
      old_note = create(:note, user: user, notable: goal, created_at: 2.days.ago)
      new_note = create(:note, user: user, notable: goal, created_at: 1.day.ago)

      expect(Note.ordered).to eq([new_note, old_note])
    end
  end

  describe "polymorphism" do
    let(:user) { create(:user) }

    it "can belong to a goal" do
      goal = create(:goal, user: user)
      note = create(:note, user: user, notable: goal)
      expect(note.notable).to eq(goal)
    end

    it "can belong to a project" do
      project = create(:project, user: user)
      note = create(:note, user: user, notable: project)
      expect(note.notable).to eq(project)
    end

    it "can belong to a todo" do
      todo = create(:todo, user: user)
      note = create(:note, user: user, notable: todo)
      expect(note.notable).to eq(todo)
    end

    it "can belong to a daily page" do
      daily_page = create(:daily_page, user: user)
      note = create(:note, user: user, notable: daily_page)
      expect(note.notable).to eq(daily_page)
    end
  end
end
