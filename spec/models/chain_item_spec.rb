require "rails_helper"

RSpec.describe ChainItem, type: :model do
  describe "associations" do
    it { should belong_to(:chain) }
    it { should belong_to(:todo).optional }
    it { should belong_to(:target_project).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
  end

  describe "#activated?" do
    it "returns false when todo_id is not set" do
      item = build(:chain_item)
      expect(item.activated?).to be false
    end

    it "returns true when todo_id is set" do
      todo = create(:todo)
      item = build(:chain_item, todo_id: todo.id)
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
