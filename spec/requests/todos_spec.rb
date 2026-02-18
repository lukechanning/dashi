require 'rails_helper'

RSpec.describe "Todos", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "POST /todos" do
    it "creates a standalone todo" do
      expect {
        post todos_path, params: { todo: { title: "Mow the lawn", due_date: Date.current } }
      }.to change(user.todos, :count).by(1)

      expect(Todo.last.project).to be_nil
    end

    it "creates a todo linked to a project" do
      project = create(:project, user: user)
      post todos_path, params: { todo: { title: "Run 5k", project_id: project.id, due_date: Date.current } }
      expect(Todo.last.project).to eq(project)
    end

    it "rejects invalid todos" do
      post todos_path, params: { todo: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /todos/:id" do
    it "updates the todo" do
      todo = create(:todo, user: user)
      patch todo_path(todo), params: { todo: { title: "Updated" } }
      expect(todo.reload.title).to eq("Updated")
    end
  end

  describe "PATCH /todos/:id/toggle" do
    it "completes an incomplete todo" do
      todo = create(:todo, user: user)
      patch toggle_todo_path(todo)
      expect(todo.reload).to be_complete
    end

    it "uncompletes a completed todo" do
      todo = create(:todo, :completed, user: user)
      patch toggle_todo_path(todo)
      expect(todo.reload).not_to be_complete
    end
  end

  describe "DELETE /todos/:id" do
    it "destroys the todo" do
      todo = create(:todo, user: user)
      expect { delete todo_path(todo) }.to change(Todo, :count).by(-1)
    end
  end
end
