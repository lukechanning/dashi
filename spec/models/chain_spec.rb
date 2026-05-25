require "rails_helper"

RSpec.describe Chain, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:chain_items).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
  end

  describe "#next_item_after" do
    let(:chain) { create(:chain) }
    let!(:item0) { create(:chain_item, chain: chain, position: 0) }
    let!(:item1) { create(:chain_item, chain: chain, position: 1) }
    let!(:item2) { create(:chain_item, chain: chain, position: 2) }

    it "returns the item immediately after the given one" do
      expect(chain.next_item_after(item0)).to eq(item1)
    end

    it "returns nil when given the last item" do
      expect(chain.next_item_after(item2)).to be_nil
    end
  end

  describe "#all_items_complete?" do
    let(:chain) { create(:chain) }

    context "when all items are completed" do
      it "returns true" do
        create(:chain_item, :completed, chain: chain, position: 0)
        create(:chain_item, :completed, chain: chain, position: 1)
        expect(chain.all_items_complete?).to be true
      end
    end

    context "when some items are incomplete" do
      it "returns false" do
        create(:chain_item, :completed, chain: chain, position: 0)
        create(:chain_item, chain: chain, position: 1)
        expect(chain.all_items_complete?).to be false
      end
    end

    context "when there are no items" do
      it "returns true (vacuously)" do
        expect(chain.all_items_complete?).to be true
      end
    end
  end

  describe "#complete!" do
    it "sets completed_at" do
      chain = create(:chain)
      freeze_time do
        chain.complete!
        expect(chain.completed_at).to eq(Time.current)
      end
    end
  end

  describe "#complete?" do
    it "returns false when completed_at is nil" do
      chain = build(:chain)
      expect(chain.complete?).to be false
    end

    it "returns true when completed_at is set" do
      chain = build(:chain, :completed)
      expect(chain.complete?).to be true
    end
  end
end
