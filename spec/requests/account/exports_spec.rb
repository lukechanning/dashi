require 'rails_helper'

RSpec.describe "Account::Exports", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /account/export" do
    it "returns a JSON file download" do
      get account_export_path
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/json")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include(".json")
    end

    it "includes meta with user email and exported_at" do
      get account_export_path
      data = JSON.parse(response.body)
      expect(data.dig("meta", "user_email")).to eq(user.email)
      expect(data.dig("meta", "exported_at")).to be_present
    end

    it "includes the user's goals" do
      create(:goal, user: user, title: "Get fit")
      get account_export_path
      data = JSON.parse(response.body)
      expect(data["goals"].map { |g| g["title"] }).to include("Get fit")
    end

    it "does not include another user's goals" do
      other_user = create(:user)
      create(:goal, user: other_user, title: "Other goal")
      get account_export_path
      data = JSON.parse(response.body)
      expect(data["goals"].map { |g| g["title"] }).not_to include("Other goal")
    end

    it "includes standalone todos" do
      create(:todo, user: user, title: "Buy milk", project: nil)
      get account_export_path
      data = JSON.parse(response.body)
      expect(data["standalone_todos"].map { |t| t["title"] }).to include("Buy milk")
    end

    it "does not include habit-generated standalone todos" do
      habit = create(:habit, user: user, project: nil)
      create(:todo, user: user, habit: habit, project: nil, title: "Walk the dog")

      get account_export_path

      data = JSON.parse(response.body)
      expect(data["standalone_todos"].map { |t| t["title"] }).not_to include("Walk the dog")
    end

    it "does not include habit-generated project todos but keeps the habit definition" do
      goal = create(:goal, user: user)
      project = create(:project, user: user, goal: goal, title: "Health")
      habit = create(:habit, user: user, project: project, title: "Walk the dog")
      create(:todo, user: user, project: project, habit: habit, title: "Walk the dog")
      create(:todo, user: user, project: project, habit: nil, title: "Buy shoes")

      get account_export_path

      project_data = JSON.parse(response.body).dig("goals", 0, "projects", 0)
      expect(project_data["todos"].map { |t| t["title"] }).to contain_exactly("Buy shoes")
      expect(project_data["habits"].map { |h| h["title"] }).to include("Walk the dog")
    end

    it "includes daily pages" do
      create(:daily_page, user: user, date: Date.new(2026, 1, 15))
      get account_export_path
      data = JSON.parse(response.body)
      expect(data["daily_pages"].map { |p| p["date"] }).to include("2026-01-15")
    end

    it "serializes created_at with microsecond precision so re-import is idempotent" do
      create(:goal, user: user, title: "Get fit")
      get account_export_path
      exported = JSON.parse(response.body)
      result = ImportService.new(user, exported).call
      expect(result.skipped).to eq(1)
      expect(result.created).to eq(0)
    end

    it "requires authentication" do
      delete session_path
      get account_export_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
