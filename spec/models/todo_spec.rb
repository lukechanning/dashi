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

    describe ".completed_on" do
      let(:today) { Date.current }

      it "returns completed todos where completed_at is on the given date" do
        completed_today = create(:todo, :completed, user: user, due_date: today - 1)

        expect(Todo.completed_on(today)).to include(completed_today)
      end

      it "does not return incomplete todos" do
        _incomplete = create(:todo, user: user, due_date: today)

        expect(Todo.completed_on(today)).to be_empty
      end

      it "does not return todos completed on a different date" do
        completed_yesterday = create(:todo, user: user)
        completed_yesterday.update!(completed_at: 1.day.ago)

        expect(Todo.completed_on(today)).not_to include(completed_yesterday)
      end
    end

    it "returns standalone todos without a project" do
      standalone = create(:todo, user: user)
      _linked = create(:todo, :with_project, user: user)

      expect(Todo.standalone).to eq([standalone])
    end

    describe ".visible_on" do
      let(:today) { Date.current }

      it "returns incomplete todos with due_date on or before the given date" do
        past = create(:todo, user: user, due_date: today - 2)
        same_day = create(:todo, user: user, due_date: today)

        expect(Todo.visible_on(today)).to include(past, same_day)
      end

      it "returns incomplete todos with no due_date" do
        no_date = create(:todo, user: user, due_date: nil)

        expect(Todo.visible_on(today)).to include(no_date)
      end

      it "returns todos completed on the given date regardless of due_date" do
        completed_today = create(:todo, :completed, user: user, due_date: today)
        rolled_over_completed = create(:todo, :completed, user: user, due_date: today - 3)

        expect(Todo.visible_on(today)).to include(completed_today, rolled_over_completed)
      end

      it "does not return todos completed on a different date" do
        completed_yesterday = create(:todo, user: user, due_date: today - 1)
        completed_yesterday.update!(completed_at: 1.day.ago)

        expect(Todo.visible_on(today)).not_to include(completed_yesterday)
      end

      it "does not return incomplete todos with due_date after the given date" do
        future = create(:todo, user: user, due_date: today + 1)

        expect(Todo.visible_on(today)).not_to include(future)
      end
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
