require 'rails_helper'

RSpec.describe Project, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:goal).optional }
    it { should have_many(:todos).dependent(:destroy) }
    it { should have_many(:notes).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values(active: 0, completed: 1, archived: 2) }
  end

  describe "scopes" do
    it "returns standalone projects without a goal" do
      user = create(:user)
      standalone = create(:project, user: user, goal: nil)
      goal = create(:goal, user: user)
      _linked = create(:project, user: user, goal: goal)

      expect(Project.standalone).to eq([standalone])
    end
  end

  describe "#progress" do
    it "returns 0 when there are no todos" do
      project = create(:project)
      expect(project.progress).to eq(0)
    end

    it "calculates percentage of completed todos" do
      project = create(:project)
      create_list(:todo, 3, project: project, user: project.user)
      create(:todo, :completed, project: project, user: project.user)

      expect(project.progress).to eq(25)
    end
  end
end
