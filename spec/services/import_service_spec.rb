require 'rails_helper'

RSpec.describe ImportService do
  let(:user) { create(:user) }

  def build_v2_export(overrides = {})
    {
      "meta" => {
        "schema_version" => 2,
        "export_id" => "export-1",
        "source_account_key" => "user:source",
        "exported_at" => "2026-01-01T00:00:00.000000Z",
        "user_email" => user.email
      },
      "preferences" => {},
      "goals" => [],
      "projects" => [],
      "todos" => [],
      "habits" => [],
      "daily_pages" => [],
      "notes" => [],
      "chains" => []
    }.deep_merge(overrides)
  end

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

    context "importing v2 exports" do
      it "creates records once and skips them on repeat import using import mappings" do
        data = build_v2_export(
          "goals" => [ {
            "source_id" => "goal-1",
            "title" => "Get fit",
            "description" => "Stay healthy",
            "emoji" => "💪",
            "status" => "active",
            "position" => 1,
            "created_at" => "2025-06-01T00:00:00.000000Z"
          } ]
        )

        first = described_class.new(user, data).call
        second = described_class.new(user, data).call

        expect(first.created).to eq(1)
        expect(second.created).to eq(0)
        expect(second.skipped).to eq(1)
        expect(user.goals.count).to eq(1)
        expect(ImportMapping.count).to eq(1)
      end

      it "does not treat unrelated local id collisions as already imported records" do
        create(:goal, user: user, id: 123, title: "Local")
        data = build_v2_export(
          "goals" => [ {
            "source_id" => "123",
            "title" => "Imported",
            "status" => "active",
            "created_at" => "2025-06-01T00:00:00.000000Z"
          } ]
        )

        result = described_class.new(user, data).call

        expect(result.errors).to be_empty
        expect(user.goals.pluck(:title)).to include("Local", "Imported")
      end

      it "restores preferences, standalone projects and habits, notes, chains, and active todo links" do
        data = build_v2_export(
          "preferences" => {
            "timezone" => "Pacific/Auckland",
            "week_start_day" => 0,
            "appearance_theme" => "dark",
            "stale_threshold_days" => 7,
            "show_stale_banner" => false,
            "show_reflection_banner" => false
          },
          "projects" => [ {
            "source_id" => "project-1",
            "title" => "Standalone project",
            "description" => "A project",
            "emoji" => "🚀",
            "status" => "active",
            "position" => 2,
            "goal_source_id" => nil,
            "created_at" => "2025-06-02T00:00:00.000000Z"
          } ],
          "todos" => [ {
            "source_id" => "todo-1",
            "title" => "Ship it",
            "notes_text" => "Details",
            "due_date" => "2025-06-10",
            "completed_at" => nil,
            "position" => 1,
            "project_source_id" => "project-1",
            "created_at" => "2025-06-10T00:00:00.000000Z"
          } ],
          "habits" => [ {
            "source_id" => "habit-1",
            "title" => "Stretch",
            "frequency" => "custom",
            "days_of_week" => "1,3,5",
            "active" => true,
            "start_date" => "2025-06-02",
            "position" => 1,
            "project_source_id" => nil,
            "created_at" => "2025-06-02T00:00:00.000000Z"
          } ],
          "daily_pages" => [ { "source_id" => "daily-2025-06-10", "date" => "2025-06-10" } ],
          "notes" => [ {
            "source_id" => "note-1",
            "body" => "A note",
            "notable_type" => "Project",
            "notable_source_id" => "project-1",
            "created_at" => "2025-06-03T00:00:00.000000Z"
          } ],
          "chains" => [ {
            "source_id" => "chain-1",
            "title" => "Launch",
            "description" => "Steps",
            "emoji" => "✅",
            "completed_at" => nil,
            "created_at" => "2025-06-01T00:00:00.000000Z",
            "items" => [ {
              "source_id" => "chain-item-1",
              "title" => "First",
              "description" => nil,
              "position" => 0,
              "completed_at" => nil,
              "target_project_source_id" => "project-1",
              "todo_source_id" => "todo-1",
              "created_at" => "2025-06-01T01:00:00.000000Z"
            } ]
          } ]
        )

        result = described_class.new(user, data).call

        expect(result.errors).to be_empty
        expect(user.reload).to have_attributes(
          timezone: "Pacific/Auckland",
          week_start_day: 0,
          appearance_theme: "dark",
          stale_threshold_days: 7,
          show_stale_banner: false,
          show_reflection_banner: false
        )
        project = user.projects.find_by!(title: "Standalone project")
        todo = user.todos.find_by!(title: "Ship it")
        habit = user.habits.find_by!(title: "Stretch")
        chain_item = user.chains.find_by!(title: "Launch").chain_items.first
        expect(project.goal).to be_nil
        expect(todo.project).to eq(project)
        expect(habit.project).to be_nil
        expect(project.notes.first.body).to eq("A note")
        expect(user.daily_pages.find_by!(date: Date.new(2025, 6, 10))).to be_present
        expect(chain_item.target_project).to eq(project)
        expect(chain_item.todo).to eq(todo)
      end

      it "rolls back all records when a reference is unresolved" do
        data = build_v2_export(
          "goals" => [ {
            "source_id" => "goal-1",
            "title" => "Get fit",
            "status" => "active",
            "created_at" => "2025-06-01T00:00:00.000000Z"
          } ],
          "projects" => [ {
            "source_id" => "project-1",
            "title" => "Broken",
            "status" => "active",
            "goal_source_id" => "missing-goal",
            "created_at" => "2025-06-02T00:00:00.000000Z"
          } ]
        )

        expect {
          result = described_class.new(user, data).call
          expect(result.errors).not_to be_empty
        }.not_to change(Goal, :count)
      end

      it "rejects duplicate source ids without mutation" do
        data = build_v2_export(
          "goals" => [
            { "source_id" => "goal-1", "title" => "One", "status" => "active", "created_at" => "2025-06-01T00:00:00.000000Z" },
            { "source_id" => "goal-1", "title" => "Two", "status" => "active", "created_at" => "2025-06-02T00:00:00.000000Z" }
          ]
        )

        expect {
          result = described_class.new(user, data).call
          expect(result.errors.join).to include("Duplicate source_id")
        }.not_to change(Goal, :count)
      end

      it "rejects invalid enum and date values without mutation" do
        data = build_v2_export(
          "goals" => [ {
            "source_id" => "goal-1",
            "title" => "Get fit",
            "status" => "bogus",
            "created_at" => "not-a-time"
          } ]
        )

        expect {
          result = described_class.new(user, data).call
          expect(result.errors).not_to be_empty
        }.not_to change(Goal, :count)
      end

      it "rejects unsupported notable types without mutation" do
        data = build_v2_export(
          "notes" => [ {
            "source_id" => "note-1",
            "body" => "Nope",
            "notable_type" => "Membership",
            "notable_source_id" => "1",
            "created_at" => "2025-06-01T00:00:00.000000Z"
          } ]
        )

        expect {
          result = described_class.new(user, data).call
          expect(result.errors.join).to include("Unsupported notable_type")
        }.not_to change(Note, :count)
      end

      it "rejects unsupported schema versions without mutation" do
        data = build_v2_export("meta" => { "schema_version" => 3 })

        expect {
          result = described_class.new(user, data).call
          expect(result.errors.join).to include("Unsupported schema_version")
        }.not_to change(Goal, :count)
      end

      it "rejects incomplete v2 top-level shape without mutation" do
        data = build_v2_export.except("todos")

        expect {
          result = described_class.new(user, data).call
          expect(result.errors.join).to include("Missing top-level todos")
        }.not_to change(Goal, :count)
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

    context "importing habits without generated todos" do
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
            "title" => "Walk daily",
            "description" => nil,
            "emoji" => nil,
            "status" => "active",
            "position" => 1,
            "created_at" => "2025-06-02T00:00:00.000000Z",
            "notes" => [],
            "todos" => [],
            "habits" => [ {
              "id" => 1,
              "title" => "Walk the dog",
              "frequency" => "daily",
              "days_of_week" => nil,
              "active" => true,
              "start_date" => "2025-06-02",
              "position" => 1,
              "created_at" => "2025-06-02T00:00:00.000000Z"
            } ]
          } ]
        } ])
      end

      it "creates the habit without creating old todo instances" do
        expect {
          expect { described_class.new(user, export_data).call }.to change(Habit, :count).by(1)
        }.not_to change(Todo, :count)
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
