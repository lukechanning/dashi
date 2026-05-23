require "rails_helper"

RSpec.describe ChainItem, type: :model do
  describe "associations" do
    it { should belong_to(:chain) }
    it { should belong_to(:todo).optional }
    it { should belong_to(:project).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_inclusion_of(:item_type).in_array(%w[todo project]) }

    context "when both todo_id and project_id are set" do
      it "is invalid" do
        todo = create(:todo)
        project = create(:project)
        chain_item = build(:chain_item, :todo_type, todo_id: todo.id, project_id: project.id)
        expect(chain_item).not_to be_valid
        expect(chain_item.errors[:base]).to include("cannot link to both a todo and a project")
      end
    end
  end

  describe "#activated?" do
    it "returns false when neither todo_id nor project_id is set" do
      item = build(:chain_item)
      expect(item.activated?).to be false
    end

    it "returns true when todo_id is set" do
      todo = create(:todo)
      item = build(:chain_item, :todo_type, todo_id: todo.id)
      expect(item.activated?).to be true
    end

    it "returns true when project_id is set" do
      project = create(:project)
      item = build(:chain_item, :project_type, project_id: project.id)
      expect(item.activated?).to be true
    end
  end

  describe "#complete?" do
    it "returns false when completed_at is nil" do
      item = build(:chain_item)
      expect(item.complete?).to be false
    end

    it "returns true when completed_at is set" do
      item = build(:chain_item, :completed)
      expect(item.complete?).to be true
    end
  end

  describe "#complete!" do
    it "sets completed_at" do
      item = create(:chain_item)
      freeze_time do
        item.complete!
        expect(item.completed_at).to eq(Time.current)
      end
    end
  end
end
