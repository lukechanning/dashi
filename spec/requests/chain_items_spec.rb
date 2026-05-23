require "rails_helper"

RSpec.describe "ChainItems", type: :request do
  let(:user) { create(:user) }
  let(:chain) { create(:chain, user: user) }

  before { sign_in(user) }

  describe "POST /chains/:chain_id/chain_items/:id/activate" do
    let(:chain_item) { create(:chain_item, chain: chain, item_type: "todo", position: 0, title: "Do the thing") }

    it "creates a todo for the chain item" do
      expect {
        post activate_chain_chain_item_path(chain, chain_item),
             params: { due_date: Date.current.to_s },
             headers: { "Accept" => "application/json" }
      }.to change(Todo, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "links the created todo to the chain item" do
      post activate_chain_chain_item_path(chain, chain_item),
           params: { due_date: Date.current.to_s },
           headers: { "Accept" => "application/json" }

      body = JSON.parse(response.body)
      expect(body["todo_id"]).to be_present
      expect(chain_item.reload).to be_activated
    end

    context "when already activated" do
      let(:existing_todo) { create(:todo, user: user) }
      let!(:activated_item) { create(:chain_item, chain: chain, item_type: "todo", position: 0, title: "Done", todo_id: existing_todo.id) }

      it "returns 422" do
        post activate_chain_chain_item_path(chain, activated_item),
             params: { due_date: Date.current.to_s },
             headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when chain belongs to another user" do
      let(:other_user) { create(:user) }
      let(:other_chain) { create(:chain, user: other_user) }
      let(:other_item) { create(:chain_item, chain: other_chain, item_type: "todo", position: 0) }

      it "returns not found" do
        post activate_chain_chain_item_path(other_chain, other_item),
             params: { due_date: Date.current.to_s },
             headers: { "Accept" => "application/json" }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
