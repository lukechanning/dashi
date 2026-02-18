require 'rails_helper'

RSpec.describe "Goals", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /goals" do
    it "lists the user's goals" do
      create(:goal, user: user, title: "Get fit")
      get goals_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Get fit")
    end
  end

  describe "GET /goals/:id" do
    it "shows the goal" do
      goal = create(:goal, user: user, title: "Learn Spanish")
      get goal_path(goal)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Learn Spanish")
    end

    it "does not show another user's goal" do
      other_goal = create(:goal, title: "Other")
      get goal_path(other_goal)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /goals" do
    it "creates a goal" do
      expect {
        post goals_path, params: { goal: { title: "New goal" } }
      }.to change(user.goals, :count).by(1)

      expect(response).to redirect_to(goal_path(Goal.last))
    end

    it "rejects invalid goals" do
      post goals_path, params: { goal: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /goals/:id" do
    it "updates the goal" do
      goal = create(:goal, user: user)
      patch goal_path(goal), params: { goal: { title: "Updated" } }
      expect(goal.reload.title).to eq("Updated")
    end
  end

  describe "DELETE /goals/:id" do
    it "destroys the goal" do
      goal = create(:goal, user: user)
      expect { delete goal_path(goal) }.to change(Goal, :count).by(-1)
      expect(response).to redirect_to(goals_path)
    end
  end
end
