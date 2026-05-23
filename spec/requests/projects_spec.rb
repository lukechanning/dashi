require 'rails_helper'

RSpec.describe "Projects", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /projects" do
    it "lists the user's projects" do
      create(:project, user: user, title: "Run 3x/week")
      get projects_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Run 3x/week")
    end
  end

  describe "GET /projects/:id" do
    it "shows the project" do
      project = create(:project, user: user)
      get project_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(project.title)
    end

    it "displays the project's habits" do
      project = create(:project, user: user)
      habit = create(:habit, user: user, project: project, title: "Daily standup")
      get project_path(project)
      expect(response.body).to include("Daily standup")
      expect(response.body).to include("Habits")
    end
  end

  describe "POST /projects" do
    it "creates a standalone project" do
      expect {
        post projects_path, params: { project: { title: "New project" } }
      }.to change(user.projects, :count).by(1)

      expect(Project.last.goal).to be_nil
    end

    it "creates a project linked to a goal" do
      goal = create(:goal, user: user)
      post projects_path, params: { project: { title: "Linked", goal_id: goal.id } }
      expect(Project.last.goal).to eq(goal)
    end

    context "when requested as JSON (wizard)" do
      it "returns the project id and redirect path" do
        post projects_path,
             params: { project: { title: "Wizard project" } }.to_json,
             headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["id"]).to eq(Project.last.id)
        expect(body["redirect"]).to be_present
      end

      it "returns errors for an invalid project" do
        post projects_path,
             params: { project: { title: "" } }.to_json,
             headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body["errors"]).to be_present
      end
    end
  end

  describe "PATCH /projects/:id" do
    it "updates the project" do
      project = create(:project, user: user)
      patch project_path(project), params: { project: { title: "Updated" } }
      expect(project.reload.title).to eq("Updated")
    end

    context "when completing a project that finishes a chain" do
      it "sets the celebration flash to the chain name" do
        chain = create(:chain, user: user, title: "Launch sequence")
        project = create(:project, user: user)
        _item0 = create(:chain_item, :completed, chain: chain, position: 0, item_type: "todo")
        _item1 = create(:chain_item, chain: chain, position: 1, item_type: "project", project_id: project.id)

        patch project_path(project), params: { project: { status: "completed" } }

        expect(flash[:celebration]).to include("Launch sequence")
      end

      it "uses the project name when it does not finish the chain" do
        chain = create(:chain, user: user, title: "My chain")
        project = create(:project, user: user, title: "Phase one")
        _item0 = create(:chain_item, chain: chain, position: 0, item_type: "project", project_id: project.id)
        _item1 = create(:chain_item, chain: chain, position: 1, item_type: "todo")

        patch project_path(project), params: { project: { status: "completed" } }

        expect(flash[:celebration]).to include("Phase one")
        expect(flash[:celebration]).not_to include("My chain")
      end
    end
  end

  describe "DELETE /projects/:id" do
    it "destroys the project" do
      project = create(:project, user: user)
      expect { delete project_path(project) }.to change(Project, :count).by(-1)
    end
  end
end
