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
  end

  describe "PATCH /projects/:id" do
    it "updates the project" do
      project = create(:project, user: user)
      patch project_path(project), params: { project: { title: "Updated" } }
      expect(project.reload.title).to eq("Updated")
    end
  end

  describe "DELETE /projects/:id" do
    it "destroys the project" do
      project = create(:project, user: user)
      expect { delete project_path(project) }.to change(Project, :count).by(-1)
    end
  end
end
