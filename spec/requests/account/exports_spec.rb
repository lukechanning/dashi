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

    it "includes v2 meta with user email, export id, source account key, and exported_at" do
      get account_export_path
      data = JSON.parse(response.body)
      expect(data.dig("meta", "schema_version")).to eq(2)
      expect(data.dig("meta", "export_id")).to be_present
      expect(data.dig("meta", "source_account_key")).to eq("user:#{user.id}")
      expect(data.dig("meta", "user_email")).to eq(user.email)
      expect(data.dig("meta", "exported_at")).to be_present
    end

    it "includes preferences" do
      user.update!(
        timezone: "Pacific/Auckland",
        week_start_day: 0,
        appearance_theme: "dark",
        stale_threshold_days: 7,
        show_stale_banner: false,
        show_reflection_banner: false
      )

      get account_export_path

      expect(JSON.parse(response.body)["preferences"]).to include(
        "timezone" => "Pacific/Auckland",
        "week_start_day" => 0,
        "appearance_theme" => "dark",
        "stale_threshold_days" => 7,
        "show_stale_banner" => false,
        "show_reflection_banner" => false
      )
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

    it "includes standalone projects" do
      create(:project, user: user, goal: nil, title: "Standalone project")
      get account_export_path
      data = JSON.parse(response.body)
      expect(data["projects"].map { |p| p["title"] }).to include("Standalone project")
    end

    it "includes standalone todos" do
      create(:todo, user: user, title: "Buy milk", project: nil)
      get account_export_path
      data = JSON.parse(response.body)
      expect(data["todos"].map { |t| t["title"] }).to include("Buy milk")
    end

    it "does not include habit-generated standalone todos" do
      habit = create(:habit, user: user, project: nil)
      create(:todo, user: user, habit: habit, project: nil, title: "Walk the dog")

      get account_export_path

      data = JSON.parse(response.body)
      expect(data["todos"].map { |t| t["title"] }).not_to include("Walk the dog")
    end

    it "does not include habit-generated project todos but keeps the habit definition" do
      goal = create(:goal, user: user)
      project = create(:project, user: user, goal: goal, title: "Health")
      habit = create(:habit, user: user, project: project, title: "Walk the dog")
      create(:todo, user: user, project: project, habit: habit, title: "Walk the dog")
      create(:todo, user: user, project: project, habit: nil, title: "Buy shoes")

      get account_export_path

      data = JSON.parse(response.body)
      expect(data["todos"].map { |t| t["title"] }).to include("Buy shoes")
      expect(data["todos"].map { |t| t["title"] }).not_to include("Walk the dog")
      expect(data["habits"].map { |h| h["title"] }).to include("Walk the dog")
    end

    it "includes standalone habits" do
      create(:habit, user: user, project: nil, title: "Stretch")
      get account_export_path
      data = JSON.parse(response.body)
      expect(data["habits"].map { |h| h["title"] }).to include("Stretch")
    end

    it "includes chains with target project and active todo source references" do
      project = create(:project, user: user, title: "Build")
      todo = create(:todo, user: user, project: project, title: "Ship")
      chain = create(:chain, user: user, title: "Launch")
      create(:chain_item, chain: chain, title: "Step", target_project: project, todo: todo)

      get account_export_path

      chain_data = JSON.parse(response.body)["chains"].first
      item_data = chain_data["items"].first
      expect(chain_data["source_id"]).to eq(chain.id.to_s)
      expect(item_data["target_project_source_id"]).to eq(project.id.to_s)
      expect(item_data["todo_source_id"]).to eq(todo.id.to_s)
    end

    it "does not emit chain item references to records omitted from the export" do
      project = create(:project, user: user, title: "Deleted project")
      chain = create(:chain, user: user, title: "Launch")
      create(:chain_item, chain: chain, title: "Step", target_project: project)
      project.discard!

      get account_export_path

      data = JSON.parse(response.body)
      expect(data["projects"].map { |p| p["source_id"] }).not_to include(project.id.to_s)
      expect(data.dig("chains", 0, "items", 0, "target_project_source_id")).to be_nil

      result = ImportService.new(create(:user), data).call
      expect(result.errors).to be_empty
    end

    it "exports source ids and source reference fields instead of nested database ids" do
      goal = create(:goal, user: user)
      project = create(:project, user: user, goal: goal)
      create(:todo, user: user, project: project)

      get account_export_path

      data = JSON.parse(response.body)
      expect(data["goals"].first).to include("source_id" => goal.id.to_s)
      expect(data["projects"].first).to include("source_id" => project.id.to_s, "goal_source_id" => goal.id.to_s)
      expect(data["todos"].first).to include("project_source_id" => project.id.to_s)
      expect(data["goals"].first).not_to have_key("id")
      expect(data["goals"].first).not_to have_key("projects")
    end

    it "does not export sharing, session, token, or admin state" do
      user.update!(admin: true)
      create(:goal, user: user)
      create(:invitation, invited_by: user)
      user.generate_magic_token!
      user.create_session!

      get account_export_path

      data = JSON.parse(response.body)
      json = response.body
      expect(data.keys).not_to include("memberships", "members", "invitations", "sessions", "user_sessions")
      expect(json).not_to include("magic_token")
      expect(json).not_to include("\"admin\"")
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
