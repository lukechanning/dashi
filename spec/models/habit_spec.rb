require 'rails_helper'

RSpec.describe Habit, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:project).optional }
    it { should have_many(:todos).dependent(:nullify) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should define_enum_for(:frequency).with_values(daily: 0, weekdays: 1, custom: 2) }

    it "requires days_of_week when frequency is custom" do
      habit = build(:habit, :custom, days_of_week: nil)
      expect(habit).not_to be_valid
      expect(habit.errors[:days_of_week]).to include("can't be blank")
    end

    it "does not require days_of_week for daily frequency" do
      habit = build(:habit, frequency: :daily, days_of_week: nil)
      expect(habit).to be_valid
    end
  end

  describe "defaults" do
    it "sets start_date to today on create if not provided" do
      habit = create(:habit, start_date: nil)
      expect(habit.start_date).to eq(Date.current)
    end
  end

  describe "#scheduled_for?" do
    context "daily habit" do
      let(:habit) { create(:habit, start_date: Date.current - 7) }

      it "returns true for any day after start_date" do
        expect(habit.scheduled_for?(Date.current)).to be true
        expect(habit.scheduled_for?(Date.current + 1)).to be true
      end

      it "returns false before start_date" do
        expect(habit.scheduled_for?(Date.current - 8)).to be false
      end

      it "returns false when paused" do
        habit.pause!
        expect(habit.scheduled_for?(Date.current)).to be false
      end
    end

    context "weekdays habit" do
      let(:habit) { create(:habit, :weekdays, start_date: Date.current - 30) }

      it "returns true for weekdays" do
        monday = Date.current.beginning_of_week(:monday)
        expect(habit.scheduled_for?(monday)).to be true
        expect(habit.scheduled_for?(monday + 4)).to be true # Friday
      end

      it "returns false for weekends" do
        saturday = Date.current.beginning_of_week(:monday) + 5
        sunday = saturday + 1
        expect(habit.scheduled_for?(saturday)).to be false
        expect(habit.scheduled_for?(sunday)).to be false
      end
    end

    context "custom habit" do
      let(:habit) { create(:habit, :custom, start_date: Date.current - 30) } # Mon, Wed, Fri

      it "returns true for scheduled days" do
        monday = Date.current.beginning_of_week(:monday) # wday = 1
        wednesday = monday + 2 # wday = 3
        friday = monday + 4 # wday = 5
        expect(habit.scheduled_for?(monday)).to be true
        expect(habit.scheduled_for?(wednesday)).to be true
        expect(habit.scheduled_for?(friday)).to be true
      end

      it "returns false for unscheduled days" do
        tuesday = Date.current.beginning_of_week(:monday) + 1
        expect(habit.scheduled_for?(tuesday)).to be false
      end
    end
  end

  describe "#generate_todo_for!" do
    let(:habit) { create(:habit, start_date: Date.current) }

    it "creates a todo for the given date" do
      expect { habit.generate_todo_for!(Date.current) }.to change(Todo, :count).by(1)
      todo = Todo.last
      expect(todo.title).to eq(habit.title)
      expect(todo.user).to eq(habit.user)
      expect(todo.due_date).to eq(Date.current)
      expect(todo.habit).to eq(habit)
    end

    it "is idempotent — does not create duplicate todos" do
      habit.generate_todo_for!(Date.current)
      expect { habit.generate_todo_for!(Date.current) }.not_to change(Todo, :count)
    end

    it "does not create a todo when not scheduled" do
      habit = create(:habit, :paused)
      expect { habit.generate_todo_for!(Date.current) }.not_to change(Todo, :count)
    end

    it "assigns the project from the habit" do
      habit = create(:habit, :with_project)
      habit.generate_todo_for!(Date.current)
      expect(Todo.last.project).to eq(habit.project)
    end
  end

  describe "#pause! and #resume!" do
    let(:habit) { create(:habit) }

    it "pauses the habit" do
      habit.pause!
      expect(habit.reload).not_to be_active
    end

    it "resumes the habit" do
      habit.pause!
      habit.resume!
      expect(habit.reload).to be_active
    end
  end

  describe "#schedule_description" do
    it "returns 'Every day' for daily" do
      expect(build(:habit, frequency: :daily).schedule_description).to eq("Every day")
    end

    it "returns 'Weekdays' for weekdays" do
      expect(build(:habit, :weekdays).schedule_description).to eq("Weekdays")
    end

    it "returns day names for custom" do
      habit = build(:habit, :custom, days_of_week: "1,3,5")
      expect(habit.schedule_description).to eq("Mon, Wed, Fri")
    end
  end
end
