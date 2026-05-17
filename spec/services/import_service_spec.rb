require 'rails_helper'

RSpec.describe ImportService do
  let(:user) { create(:user) }

  def build_export(overrides = {})
    {
      "meta" => { "exported_at" => "2026-01-01T00:00:00Z", "user_email" => user.email },
      "goals" => [],
      "standalone_todos" => [],
      "daily_pages" => []
    }.merge(overrides)
  end

  describe "#call" do
    context "with an empty export" do
      it "returns zero counts" do
        result = described_class.new(user, build_export).call
        expect(result.created).to eq(0)
        expect(result.skipped).to eq(0)
        expect(result.errors).to be_empty
      end
    end

    context "importing goals" do
      let(:goal_data) do
        [ {
          "id" => 999,
          "title" => "Get fit",
          "description" => "Stay healthy",
          "emoji" => "💪",
          "status" => "active",
          "position" => 1,
          "created_at" => "2025-06-01T00:00:00.000000Z",
          "notes" => [],
          "projects" => []
        } ]
      end

      it "creates a new goal" do
        expect {
          described_class.new(user, build_export("goals" => goal_data)).call
        }.to change(user.goals, :count).by(1)
      end

      it "returns the correct created count" do
        result = described_class.new(user, build_export("goals" => goal_data)).call
        expect(result.created).to eq(1)
      end

      it "skips on a second import (idempotent)" do
        described_class.new(user, build_export("goals" => goal_data)).call

        # On re-import, the exported id=999 won't match the newly assigned id,
        # but the record already exists — simulate a real export by using the actual id
        goal = user.goals.last
        reimport_data = goal_data.map { |g| g.merge("id" => goal.id) }
        result = described_class.new(user, build_export("goals" => reimport_data)).call

        expect(result.skipped).to eq(1)
        expect(result.created).to eq(0)
        expect(user.goals.count).to eq(1)
      end

      it "sets the goal attributes correctly" do
        described_class.new(user, build_export("goals" => goal_data)).call
        goal = user.goals.last
        expect(goal.title).to eq("Get fit")
        expect(goal.description).to eq("Stay healthy")
        expect(goal.emoji).to eq("💪")
        expect(goal.status).to eq("active")
      end
    end

    context "importing goals with nested projects and todos" do
      let(:export_data) do
        build_export("goals" => [ {
          "id" => 1,
          "title" => "Get fit",
          "description" => nil,
          "emoji" => nil,
          "status" => "active",
          "position" => 1,
          "created_at" => "2025-06-01T00:00:00.000000Z",
          "notes" => [],
          "projects" => [ {
            "id" => 1,
            "title" => "Run 3x/week",
            "description" => nil,
            "emoji" => nil,
            "status" => "active",
            "position" => 1,
            "created_at" => "2025-06-02T00:00:00.000000Z",
            "notes" => [],
            "todos" => [ {
              "id" => 1,
              "title" => "Run 5k",
              "notes_text" => nil,
              "due_date" => "2025-06-10",
              "completed_at" => nil,
              "position" => 1,
              "created_at" => "2025-06-10T00:00:00.000000Z",
              "notes" => []
            } ],
            "habits" => []
          } ]
        } ])
      end

      it "creates goal, project, and todo" do
        expect { described_class.new(user, export_data).call }
          .to change(Goal, :count).by(1)
          .and change(Project, :count).by(1)
          .and change(Todo, :count).by(1)
      end

      it "links project to goal and todo to project" do
        described_class.new(user, export_data).call
        goal = user.goals.find_by(title: "Get fit")
        project = goal.projects.find_by(title: "Run 3x/week")
        todo = project.todos.find_by(title: "Run 5k")
        expect(project).to be_present
        expect(todo).to be_present
      end
    end

    context "importing standalone todos" do
      let(:export_data) do
        build_export("standalone_todos" => [ {
          "id" => 1,
          "title" => "Buy groceries",
          "notes_text" => nil,
          "due_date" => "2025-06-10",
          "completed_at" => nil,
          "position" => 1,
          "created_at" => "2025-06-10T00:00:00.000000Z",
          "notes" => []
        } ])
      end

      it "creates a standalone todo with no project" do
        expect { described_class.new(user, export_data).call }.to change(Todo, :count).by(1)
        todo = user.todos.find_by(title: "Buy groceries")
        expect(todo.project).to be_nil
      end
    end

    context "importing notes" do
      let(:export_data) do
        build_export("goals" => [ {
          "id" => 1,
          "title" => "Get fit",
          "description" => nil,
          "emoji" => nil,
          "status" => "active",
          "position" => 1,
          "created_at" => "2025-06-01T00:00:00.000000Z",
          "notes" => [ { "id" => 1, "body" => "A note on this goal", "created_at" => "2025-06-02T00:00:00.000000Z" } ],
          "projects" => []
        } ])
      end

      it "creates notes attached to the goal" do
        described_class.new(user, export_data).call
        goal = user.goals.find_by(title: "Get fit")
        expect(goal.notes.map(&:body)).to include("A note on this goal")
      end

      it "skips notes on re-import (idempotent by id)" do
        described_class.new(user, export_data).call
        note = user.goals.last.notes.last
        reimport = export_data.deep_dup
        reimport["goals"][0]["id"] = user.goals.last.id
        reimport["goals"][0]["notes"][0]["id"] = note.id
        expect { described_class.new(user, reimport).call }.not_to change(Note, :count)
      end
    end

    context "importing daily pages" do
      let(:export_data) do
        build_export("daily_pages" => [ {
          "date" => "2026-01-15",
          "notes" => [ { "id" => 1, "body" => "Good day", "created_at" => "2026-01-15T10:00:00.000000Z" } ]
        } ])
      end

      it "creates the daily page with its notes" do
        expect { described_class.new(user, export_data).call }
          .to change(DailyPage, :count).by(1)
          .and change(Note, :count).by(1)
      end

      it "is idempotent on re-import" do
        described_class.new(user, export_data).call
        expect { described_class.new(user, export_data).call }.not_to change(DailyPage, :count)
      end
    end

    context "with malformed data" do
      it "returns an error for non-hash input" do
        result = described_class.new(user, "not a hash").call
        expect(result.errors).not_to be_empty
      end

      it "returns an error for missing meta key" do
        result = described_class.new(user, { "goals" => [] }).call
        expect(result.errors).not_to be_empty
      end
    end
  end
end
