require "rails_helper"

RSpec.describe "Chains", type: :request do
  let(:user) { create(:user) }
  let!(:chain) { create(:chain, user: user, title: "Morning Routine") }

  before { sign_in(user) }

  describe "GET /chains" do
    it "lists the user's chains" do
      get chains_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Morning Routine")
    end

    it "does not include another user's chains" do
      other_chain = create(:chain, title: "Someone else's chain")
      get chains_path
      expect(response.body).not_to include("Someone else's chain")
    end
  end

  describe "GET /chains/:id" do
    it "shows the chain and its items" do
      create(:chain_item, chain: chain, position: 0, title: "First step")
      get chain_path(chain)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("First step")
    end

    it "returns not found for another user's chain" do
      other_chain = create(:chain)
      get chain_path(other_chain)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /chains/:id" do
    it "soft-deletes the chain" do
      expect { delete chain_path(chain) }.not_to change(Chain.unscoped, :count)
      expect(response).to redirect_to(root_path)
      expect(chain.reload.deleted_at).to be_present
    end

    it "does not destroy another user's chain" do
      other_chain = create(:chain)
      expect { delete chain_path(other_chain) }.not_to change(Chain.unscoped, :count)
    end
  end

  describe "POST /chains" do
    let(:valid_payload) do
      {
        chain: {
          title: "Morning Routine",
          chain_items_attributes: [
            { title: "Meditate", item_type: "todo", position: 0, due_date: Date.current.to_s },
            { title: "Exercise", item_type: "todo", position: 1 }
          ]
        }
      }
    end

    it "creates a chain with items" do
      expect {
        post chains_path, params: valid_payload.to_json,
             headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      }.to change(Chain, :count).by(1)
        .and change(ChainItem, :count).by(2)

      expect(response).to have_http_status(:created)
    end

    it "activates the first item as a todo" do
      post chains_path, params: valid_payload.to_json,
           headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

      first_item = Chain.last.chain_items.first
      expect(first_item).to be_activated
      expect(first_item.todo).to be_a(Todo)
    end

    it "returns the redirect path in JSON" do
      post chains_path, params: valid_payload.to_json,
           headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

      body = JSON.parse(response.body)
      expect(body).to have_key("redirect")
    end

    it "returns 422 when title is missing" do
      post chains_path, params: { chain: { title: "", chain_items_attributes: [] } }.to_json,
           headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to be_present
    end

    it "does not let a user create chains for another user" do
      post chains_path, params: valid_payload.to_json,
           headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      expect(Chain.last.user).to eq(user)
    end
  end
end
