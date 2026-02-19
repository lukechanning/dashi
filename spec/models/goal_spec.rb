require 'rails_helper'

RSpec.describe Goal, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:projects).dependent(:destroy) }
    it { should have_many(:todos).through(:projects) }
    it { should have_many(:notes).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values(active: 0, completed: 1, archived: 2) }
  end

  describe "scopes" do
    it "orders by position" do
      user = create(:user)
      goal_b = create(:goal, user: user, position: 2)
      goal_a = create(:goal, user: user, position: 1)

      expect(Goal.ordered).to eq([goal_a, goal_b])
    end
  end

  describe "#momentum" do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }

    it "returns :new when there are no todos across any project" do
      create(:project, user: user, goal: goal)
      expect(goal.momentum).to eq(:new)
    end

    it "returns :cool when todos exist but none completed in last 7 days" do
      project = create(:project, user: user, goal: goal)
      create(:todo, :completed, user: user, project: project,
             completed_at: 8.days.ago)
      expect(goal.momentum).to eq(:cool)
    end

    it "returns :warm when 1-2 todos completed in last 7 days across projects" do
      project1 = create(:project, user: user, goal: goal)
      project2 = create(:project, user: user, goal: goal)
      create(:todo, :completed, user: user, project: project1)
      create(:todo, :completed, user: user, project: project2,
             completed_at: 8.days.ago)
      expect(goal.momentum).to eq(:warm)
    end

    it "returns :hot when 3+ todos completed in last 7 days across projects" do
      project1 = create(:project, user: user, goal: goal)
      project2 = create(:project, user: user, goal: goal)
      create_list(:todo, 2, :completed, user: user, project: project1)
      create(:todo, :completed, user: user, project: project2)
      expect(goal.momentum).to eq(:hot)
    end
  end

  describe "#momentum_label" do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }

    it "returns 'Just started' for :new" do
      expect(goal.momentum_label).to eq("Just started")
    end

    it "returns 'Active' for :hot" do
      project = create(:project, user: user, goal: goal)
      create_list(:todo, 3, :completed, user: user, project: project)
      expect(goal.momentum_label).to eq("Active")
    end
  end

  describe "#activity_weeks" do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }

    it "returns 16 columns of 7 cells each" do
      result = goal.activity_weeks
      expect(result[:columns].length).to eq(16)
      expect(result[:columns].first.length).to eq(7)
    end

    it "aggregates counts across all projects for today's cell" do
      project1 = create(:project, user: user, goal: goal)
      project2 = create(:project, user: user, goal: goal)
      today = Date.current
      create(:todo, :completed, user: user, project: project1,
             completed_at: today.beginning_of_day + 1.hour)
      create(:todo, :completed, user: user, project: project2,
             completed_at: today.beginning_of_day + 2.hours)
      result = goal.activity_weeks
      today_cell = result[:columns].flatten.find { |c| c[:date] == today }
      expect(today_cell[:count]).to eq(2)
    end

    it "marks future cells with future: true and count 0" do
      result = goal.activity_weeks
      future_cells = result[:columns].flatten.select { |c| c[:future] }
      expect(future_cells).to all(include(count: 0, future: true))
    end

    it "excludes todos completed before the 16-week window" do
      project = create(:project, user: user, goal: goal)
      create(:todo, :completed, user: user, project: project,
             completed_at: 17.weeks.ago)
      result = goal.activity_weeks
      total = result[:columns].flatten.reject { |c| c[:future] }.sum { |c| c[:count] }
      expect(total).to eq(0)
    end
  end

  describe "#weekly_activity" do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }

    it "returns 12 entries" do
      expect(goal.weekly_activity.length).to eq(12)
    end

    it "aggregates completions across projects for the current week" do
      project1 = create(:project, user: user, goal: goal)
      project2 = create(:project, user: user, goal: goal)
      today = Date.current
      create_list(:todo, 2, :completed, user: user, project: project1,
                  completed_at: today.beginning_of_day + 1.hour)
      create(:todo, :completed, user: user, project: project2,
             completed_at: today.beginning_of_day + 2.hours)
      result = goal.weekly_activity
      expect(result.last).to eq(3)
    end

    it "excludes completions before the 12-week window" do
      project = create(:project, user: user, goal: goal)
      create(:todo, :completed, user: user, project: project,
             completed_at: 13.weeks.ago)
      expect(goal.weekly_activity.sum).to eq(0)
    end
  end
end
