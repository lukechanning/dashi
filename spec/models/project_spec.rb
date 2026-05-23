require 'rails_helper'

RSpec.describe Project, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:goal).optional }
    it { should have_many(:todos).dependent(:destroy) }
    it { should have_many(:notes).dependent(:destroy) }
    it { should have_one(:chain_item) }
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

      expect(Project.standalone).to eq([ standalone ])
    end
  end

  describe "chain completion callback" do
    let(:user) { create(:user) }

    context "when a project in a chain is marked completed" do
      it "marks the chain item as complete" do
        chain = create(:chain, user: user)
        project = create(:project, user: user)
        chain_item = create(:chain_item, chain: chain, position: 0, item_type: "project", project_id: project.id)

        project.update!(status: :completed)

        expect(chain_item.reload).to be_complete
      end

      it "marks the whole chain complete when it is the last item" do
        chain = create(:chain, user: user)
        project = create(:project, user: user)
        _item0 = create(:chain_item, :completed, chain: chain, position: 0, item_type: "todo")
        _item1 = create(:chain_item, chain: chain, position: 1, item_type: "project", project_id: project.id)

        project.update!(status: :completed)

        expect(chain.reload).to be_complete
      end

      it "does not mark the chain complete when other items are still pending" do
        chain = create(:chain, user: user)
        project = create(:project, user: user)
        _item0 = create(:chain_item, chain: chain, position: 0, item_type: "project", project_id: project.id)
        _item1 = create(:chain_item, chain: chain, position: 1, item_type: "todo")

        project.update!(status: :completed)

        expect(chain.reload).not_to be_complete
      end
    end

    context "when a project is archived (not completed)" do
      it "does not touch the chain item" do
        chain = create(:chain, user: user)
        project = create(:project, user: user)
        chain_item = create(:chain_item, chain: chain, position: 0, item_type: "project", project_id: project.id)

        project.update!(status: :archived)

        expect(chain_item.reload).not_to be_complete
      end
    end

    context "when the project has no chain item" do
      it "does not raise" do
        project = create(:project, user: user)
        expect { project.update!(status: :completed) }.not_to raise_error
      end
    end
  end

  describe "#momentum" do
    let(:project) { create(:project) }

    it "returns :new when there are no todos" do
      expect(project.momentum).to eq(:new)
    end

    it "returns :cool when todos exist but none completed in last 7 days" do
      create(:todo, :completed, project: project, user: project.user,
             completed_at: 8.days.ago)
      expect(project.momentum).to eq(:cool)
    end

    it "returns :warm when 1-2 todos completed in last 7 days" do
      create_list(:todo, 2, :completed, project: project, user: project.user)
      expect(project.momentum).to eq(:warm)
    end

    it "returns :hot when 3+ todos completed in last 7 days" do
      create_list(:todo, 3, :completed, project: project, user: project.user)
      expect(project.momentum).to eq(:hot)
    end
  end

  describe "#momentum_label" do
    let(:project) { create(:project) }

    it "returns 'Just started' for :new" do
      expect(project.momentum_label).to eq("Just started")
    end

    it "returns 'Active' for :hot" do
      create_list(:todo, 3, :completed, project: project, user: project.user)
      expect(project.momentum_label).to eq("Active")
    end
  end

  describe "#activity_weeks" do
    let(:project) { create(:project) }

    it "returns 16 columns of 7 cells each" do
      result = project.activity_weeks
      expect(result[:columns].length).to eq(16)
      expect(result[:columns].first.length).to eq(7)
    end

    it "reflects the correct count for today's cell" do
      today = Date.current
      create_list(:todo, 3, :completed, project: project, user: project.user,
                  completed_at: today.beginning_of_day + 1.hour)
      result = project.activity_weeks
      today_cell = result[:columns].flatten.find { |c| c[:date] == today }
      expect(today_cell[:count]).to eq(3)
    end

    it "marks future cells with future: true and count 0" do
      result = project.activity_weeks
      future_cells = result[:columns].flatten.select { |c| c[:future] }
      expect(future_cells).to all(include(count: 0, future: true))
    end

    it "excludes todos completed before the 16-week window" do
      create(:todo, :completed, project: project, user: project.user,
             completed_at: 17.weeks.ago)
      result = project.activity_weeks
      total = result[:columns].flatten.reject { |c| c[:future] }.sum { |c| c[:count] }
      expect(total).to eq(0)
    end
  end

  describe "#weekly_activity" do
    let(:project) { create(:project) }

    it "returns 12 entries" do
      expect(project.weekly_activity.length).to eq(12)
    end

    it "reflects completions in the current week" do
      today = Date.current
      create_list(:todo, 4, :completed, project: project, user: project.user,
                  completed_at: today.beginning_of_day + 1.hour)
      result = project.weekly_activity
      expect(result.last).to eq(4)
    end

    it "excludes completions before the 12-week window" do
      create(:todo, :completed, project: project, user: project.user,
             completed_at: 13.weeks.ago)
      expect(project.weekly_activity.sum).to eq(0)
    end
  end
end
