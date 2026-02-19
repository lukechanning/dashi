require 'rails_helper'

RSpec.describe Todo, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:project).optional }
    it { should have_many(:notes).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
  end

  describe "scopes" do
    let(:user) { create(:user) }

    it "returns complete todos" do
      complete = create(:todo, :completed, user: user)
      _incomplete = create(:todo, user: user)

      expect(Todo.complete).to eq([complete])
    end

    it "returns incomplete todos" do
      _complete = create(:todo, :completed, user: user)
      incomplete = create(:todo, user: user)

      expect(Todo.incomplete).to eq([incomplete])
    end

    it "returns todos due on a specific date" do
      today = create(:todo, user: user, due_date: Date.current)
      _tomorrow = create(:todo, user: user, due_date: Date.tomorrow)

      expect(Todo.due_on(Date.current)).to eq([today])
    end

    it "returns overdue todos" do
      overdue = create(:todo, :overdue, user: user)
      _today = create(:todo, user: user, due_date: Date.current)

      expect(Todo.overdue).to eq([overdue])
    end

    it "returns standalone todos without a project" do
      standalone = create(:todo, user: user)
      _linked = create(:todo, :with_project, user: user)

      expect(Todo.standalone).to eq([standalone])
    end
  end

  describe "#complete!" do
    it "sets completed_at to current time" do
      todo = create(:todo)
      freeze_time do
        todo.complete!
        expect(todo.completed_at).to eq(Time.current)
      end
    end
  end

  describe "#incomplete!" do
    it "clears completed_at" do
      todo = create(:todo, :completed)
      todo.incomplete!
      expect(todo.completed_at).to be_nil
    end
  end

  describe "#complete?" do
    it "returns true when completed" do
      expect(build(:todo, :completed)).to be_complete
    end

    it "returns false when not completed" do
      expect(build(:todo)).not_to be_complete
    end
  end
end
