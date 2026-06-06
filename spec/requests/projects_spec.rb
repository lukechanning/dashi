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

    it "keeps inactive projects in a separate section when requested" do
      create(:project, user: user, title: "Active Project", status: :active)
      create(:project, user: user, title: "Archived Project", status: :archived)

      get projects_path(show_all: 1)

      expect(response.body).to include("data-testid=\"active-projects\"")
      expect(response.body).to include("data-testid=\"inactive-projects\"")
      expect(response.body).to match(
        /data-testid="active-projects".*Active Project.*data-testid="inactive-projects".*Archived Project/m
      )
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

    it "soft-deletes the source todo when creating a project from a todo" do
      todo = create(:todo, user: user)

      expect {
        post projects_path, params: { from_todo: todo.id, project: { title: "From todo" } }
      }.not_to change(Todo.unscoped, :count)

      expect(todo.reload.deleted_at).to be_present
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
  end

  describe "DELETE /projects/:id" do
    it "soft-deletes the project" do
      project = create(:project, user: user)
      expect { delete project_path(project) }.not_to change(Project.unscoped, :count)
      expect(project.reload.deleted_at).to be_present
    end
  end
end
