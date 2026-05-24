require "rails_helper"

RSpec.describe ChainItems::ActivateService do
  let(:user) { create(:user) }
  let(:chain) { create(:chain, user: user) }

  describe "#call" do
    context "for a chain item" do
      let(:chain_item) { create(:chain_item, chain: chain, position: 0, title: "Go for a run") }
      let(:due_date) { Date.current + 1.day }

      it "creates a todo with the correct title and due date" do
        result = described_class.new(chain_item, due_date: due_date).call
        expect(result.success?).to be true
        expect(result.todo).to be_a(Todo)
        expect(result.todo.title).to eq("Go for a run")
        expect(result.todo.due_date).to eq(due_date)
      end

      it "links the todo to the chain item" do
        result = described_class.new(chain_item, due_date: due_date).call
        expect(chain_item.reload.todo_id).to eq(result.todo.id)
      end

      it "assigns the todo to the chain's user" do
        result = described_class.new(chain_item, due_date: due_date).call
        expect(result.todo.user).to eq(user)
      end
    end

    context "when the chain item is already activated" do
      let(:existing_todo) { create(:todo, user: user) }
      let!(:chain_item) { create(:chain_item, chain: chain, position: 0, todo_id: existing_todo.id) }

      it "returns a failure result" do
        result = described_class.new(chain_item, due_date: Date.current).call
        expect(result.success?).to be false
        expect(result.errors).to include("Already activated")
      end

      it "does not create additional records" do
        expect {
          described_class.new(chain_item, due_date: Date.current).call
        }.not_to change(Todo, :count)
      end
    end
  end
end
