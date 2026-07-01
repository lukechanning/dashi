module Account
  class ExportsController < ApplicationController
    def show
      data = build_export_data
      filename = "dashi-export-#{Date.current.iso8601}.json"
      send_data data.to_json, filename: filename, type: "application/json", disposition: "attachment"
    end

    private

    def build_export_data
      user = current_user
      {
        meta: {
          exported_at: Time.current.iso8601(6),
          user_email: user.email
        },
        goals: user.goals.includes(:notes, projects: [ :notes, :todos, { todos: :notes }, :habits ]).map { |g| serialize_goal(g) },
        standalone_todos: user.todos.standalone.where(habit_id: nil).includes(:notes).map { |t| serialize_todo(t) },
        daily_pages: user.daily_pages.includes(:notes).map { |p| serialize_daily_page(p) }
      }
    end

    def serialize_goal(goal)
      {
        id: goal.id,
        title: goal.title,
        description: goal.description,
        emoji: goal.emoji,
        status: goal.status,
        position: goal.position,
        created_at: goal.created_at.iso8601(6),
        notes: goal.notes.map { |n| serialize_note(n) },
        projects: goal.projects.map { |p| serialize_project(p) }
      }
    end

    def serialize_project(project)
      {
        id: project.id,
        title: project.title,
        description: project.description,
        emoji: project.emoji,
        status: project.status,
        position: project.position,
        created_at: project.created_at.iso8601(6),
        notes: project.notes.map { |n| serialize_note(n) },
        todos: project.todos.select { |t| t.habit_id.nil? }.map { |t| serialize_todo(t) },
        habits: project.habits.map { |h| serialize_habit(h) }
      }
    end

    def serialize_todo(todo)
      {
        id: todo.id,
        title: todo.title,
        notes_text: todo.read_attribute(:notes),
        due_date: todo.due_date&.iso8601,
        completed_at: todo.completed_at&.iso8601(6),
        position: todo.position,
        created_at: todo.created_at.iso8601(6),
        notes: todo.notes.map { |n| serialize_note(n) }
      }
    end

    def serialize_habit(habit)
      {
        id: habit.id,
        title: habit.title,
        frequency: habit.frequency,
        days_of_week: habit.days_of_week,
        active: habit.active,
        start_date: habit.start_date&.iso8601,
        position: habit.position,
        created_at: habit.created_at.iso8601(6)
      }
    end

    def serialize_daily_page(page)
      {
        date: page.date.iso8601,
        notes: page.notes.map { |n| serialize_note(n) }
      }
    end

    def serialize_note(note)
      {
        id: note.id,
        body: note.body,
        created_at: note.created_at.iso8601(6)
      }
    end
  end
end
