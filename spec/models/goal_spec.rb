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

  describe "#progress" do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }

    it "returns 0 when there are no projects" do
      expect(goal.progress).to eq(0)
    end

    it "returns 0 when there are no todos" do
      create(:project, user: user, goal: goal)
      expect(goal.progress).to eq(0)
    end

    it "calculates progress across all projects' todos" do
      project1 = create(:project, user: user, goal: goal)
      project2 = create(:project, user: user, goal: goal)
      create(:todo, user: user, project: project1)
      create(:todo, :completed, user: user, project: project1)
      create(:todo, user: user, project: project2)
      create(:todo, :completed, user: user, project: project2)

      expect(goal.progress).to eq(50)
    end
  end
end
