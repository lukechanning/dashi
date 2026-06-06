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

    it "responds with JSON including completed_at when requested" do
      todo = create(:todo, user: user)
      patch toggle_todo_path(todo), headers: { "Accept" => "application/json" }
      expect(response.content_type).to include("application/json")
      body = JSON.parse(response.body)
      expect(body).to have_key("completed_at")
    end

    it "responds with JSON with null completed_at when uncompleting" do
      todo = create(:todo, :completed, user: user)
      patch toggle_todo_path(todo), headers: { "Accept" => "application/json" }
      body = JSON.parse(response.body)
      expect(body["completed_at"]).to be_nil
    end

    it "responds with null chain context for non-chained todos" do
      todo = create(:todo, user: user)
      patch toggle_todo_path(todo), headers: { "Accept" => "application/json" }
      body = JSON.parse(response.body)
      expect(body["chain"]).to be_nil
    end

    context "when completing a mid-chain todo" do
      it "returns next chain item info" do
        chain = create(:chain, user: user)
        todo = create(:todo, user: user)
        item0 = create(:chain_item, chain: chain, position: 0, title: "First step", todo_id: todo.id)
        _item1 = create(:chain_item, chain: chain, position: 1, title: "Second step")

        patch toggle_todo_path(todo), headers: { "Accept" => "application/json" }
        body = JSON.parse(response.body)

        expect(body["chain"]).to include(
          "chain_id" => chain.id,
          "next_title" => "Second step"
        )
        expect(body["chain"]["chain_complete"]).to be_nil
      end
    end

    context "when completing the last todo in a chain" do
      it "returns chain_complete: true and marks the chain complete" do
        chain = create(:chain, user: user)
        todo = create(:todo, user: user)
        _item0 = create(:chain_item, :completed, chain: chain, position: 0, title: "Already done")
        _item1 = create(:chain_item, chain: chain, position: 1, title: "Last step", todo_id: todo.id)

        patch toggle_todo_path(todo), headers: { "Accept" => "application/json" }
        body = JSON.parse(response.body)

        expect(body["chain"]).to include("chain_complete" => true, "chain_title" => chain.title)
        expect(chain.reload).to be_complete
      end
    end

    context "when un-completing a chained todo" do
      it "returns null chain context" do
        chain = create(:chain, user: user)
        todo = create(:todo, :completed, user: user)
        _item = create(:chain_item, chain: chain, position: 0, todo_id: todo.id)

        patch toggle_todo_path(todo), headers: { "Accept" => "application/json" }
        body = JSON.parse(response.body)

        expect(body["chain"]).to be_nil
      end
    end
  end

  describe "GET /todos/:id/edit" do
    it "shows a delete button" do
      todo = create(:todo, user: user)
      get edit_todo_path(todo)
      expect(response.body).to include("Delete this todo")
    end
  end

  describe "DELETE /todos/:id" do
    it "soft-deletes the todo" do
      todo = create(:todo, user: user)
      expect { delete todo_path(todo) }.not_to change(Todo.unscoped, :count)
      expect(todo.reload.deleted_at).to be_present
    end
  end
end
