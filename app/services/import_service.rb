class ImportService
  Result = Data.define(:created, :skipped, :errors)

  def initialize(user, data)
    @user = user
    @data = data
    @created = 0
    @skipped = 0
    @errors = []
  end

  def call
    return error_result("Invalid data format") unless @data.is_a?(Hash)
    return error_result("Missing meta section") unless @data.key?("meta")

    import_goals
    import_standalone_todos
    import_daily_pages

    Result.new(created: @created, skipped: @skipped, errors: @errors)
  rescue => e
    error_result(e.message)
  end

  private

  def import_goals
    Array(@data["goals"]).each do |goal_data|
      goal = find_or_create_goal(goal_data)
      import_notes(goal, Array(goal_data["notes"]))
      import_projects(goal, Array(goal_data["projects"]))
    end
  end

  def find_or_create_goal(data)
    existing = @user.goals.find_by(id: data["id"])
    if existing
      @skipped += 1
      existing
    else
      goal = @user.goals.create!(
        title: data["title"],
        description: data["description"],
        emoji: data["emoji"],
        status: data["status"] || "active",
        position: data["position"],
        created_at: parse_time(data["created_at"])
      )
      @created += 1
      goal
    end
  end

  def import_projects(goal, projects_data)
    projects_data.each do |project_data|
      project = find_or_create_project(goal, project_data)
      import_notes(project, Array(project_data["notes"]))
      import_todos(project, Array(project_data["todos"]))
      import_habits(project, Array(project_data["habits"]))
    end
  end

  def find_or_create_project(goal, data)
    existing = @user.projects.find_by(id: data["id"])
    if existing
      @skipped += 1
      existing
    else
      project = @user.projects.create!(
        title: data["title"],
        description: data["description"],
        emoji: data["emoji"],
        status: data["status"] || "active",
        position: data["position"],
        goal: goal,
        created_at: parse_time(data["created_at"])
      )
      @created += 1
      project
    end
  end

  def import_todos(project, todos_data)
    todos_data.each { |td| find_or_create_todo(td, project: project) }
  end

  def import_standalone_todos
    Array(@data["standalone_todos"]).each { |td| find_or_create_todo(td, project: nil) }
  end

  def find_or_create_todo(data, project:)
    existing = @user.todos.find_by(id: data["id"])
    if existing
      @skipped += 1
      existing
    else
      todo = @user.todos.build(
        title: data["title"],
        due_date: data["due_date"],
        completed_at: data["completed_at"],
        position: data["position"],
        project: project,
        created_at: parse_time(data["created_at"])
      )
      todo.write_attribute(:notes, data["notes_text"])
      todo.save!
      @created += 1
      import_notes(todo, Array(data["notes"]))
      todo
    end
  end

  def import_habits(project, habits_data)
    habits_data.each do |data|
      existing = @user.habits.find_by(id: data["id"])
      if existing
        @skipped += 1
      else
        @user.habits.create!(
          title: data["title"],
          frequency: data["frequency"] || "daily",
          days_of_week: data["days_of_week"],
          active: data.fetch("active", true),
          position: data["position"],
          start_date: data["start_date"],
          project: project
        )
        @created += 1
      end
    end
  end

  def import_daily_pages
    Array(@data["daily_pages"]).each do |page_data|
      page = @user.daily_pages.find_or_initialize_by(date: page_data["date"])
      if page.new_record?
        page.save!
        @created += 1
      else
        @skipped += 1
      end
      import_notes(page, Array(page_data["notes"]))
    end
  end

  def import_notes(notable, notes_data)
    notes_data.each do |note_data|
      existing = notable.notes.find_by(id: note_data["id"])
      unless existing
        notable.notes.create!(
          body: note_data["body"],
          user: @user,
          created_at: parse_time(note_data["created_at"])
        )
        @created += 1
      end
    end
  end

  def parse_time(value)
    value ? Time.zone.parse(value.to_s) : nil
  rescue ArgumentError
    nil
  end

  def error_result(message)
    Result.new(created: 0, skipped: 0, errors: [ message ])
  end
end
