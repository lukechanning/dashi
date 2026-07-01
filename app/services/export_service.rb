class ExportService
  SCHEMA_VERSION = 2

  def initialize(user)
    @user = user
  end

  def call
    {
      meta: {
        schema_version: SCHEMA_VERSION,
        export_id: SecureRandom.uuid,
        source_account_key: source_account_key,
        exported_at: Time.current.iso8601(6),
        user_email: user.email
      },
      preferences: serialize_preferences,
      goals: user.goals.ordered.includes(:notes).map { |goal| serialize_goal(goal) },
      projects: user.projects.ordered.includes(:notes).map { |project| serialize_project(project) },
      todos: user.todos.where(habit_id: nil).ordered.includes(:notes).map { |todo| serialize_todo(todo) },
      habits: user.habits.ordered.map { |habit| serialize_habit(habit) },
      daily_pages: user.daily_pages.order(:date).includes(:notes).map { |page| serialize_daily_page(page) },
      notes: user.notes.order(:created_at).map { |note| serialize_note(note) },
      chains: user.chains.includes(chain_items: [ :target_project, :todo ]).order(:created_at).map { |chain| serialize_chain(chain) }
    }
  end

  private

  attr_reader :user

  def source_account_key
    "user:#{user.id}"
  end

  def serialize_preferences
    {
      timezone: user.timezone,
      week_start_day: user.week_start_day,
      appearance_theme: user.appearance_theme,
      stale_threshold_days: user.stale_threshold_days,
      show_stale_banner: user.show_stale_banner,
      show_reflection_banner: user.show_reflection_banner
    }
  end

  def serialize_goal(goal)
    {
      source_id: goal.id.to_s,
      title: goal.title,
      description: goal.description,
      emoji: goal.emoji,
      status: goal.status,
      position: goal.position,
      created_at: goal.created_at.iso8601(6)
    }
  end

  def serialize_project(project)
    {
      source_id: project.id.to_s,
      title: project.title,
      description: project.description,
      emoji: project.emoji,
      status: project.status,
      position: project.position,
      goal_source_id: project.goal_id&.to_s,
      created_at: project.created_at.iso8601(6)
    }
  end

  def serialize_todo(todo)
    {
      source_id: todo.id.to_s,
      title: todo.title,
      notes_text: todo.read_attribute(:notes),
      due_date: todo.due_date&.iso8601,
      completed_at: todo.completed_at&.iso8601(6),
      position: todo.position,
      project_source_id: todo.project_id&.to_s,
      created_at: todo.created_at.iso8601(6)
    }
  end

  def serialize_habit(habit)
    {
      source_id: habit.id.to_s,
      title: habit.title,
      frequency: habit.frequency,
      days_of_week: habit.days_of_week,
      active: habit.active,
      start_date: habit.start_date&.iso8601,
      position: habit.position,
      project_source_id: habit.project_id&.to_s,
      created_at: habit.created_at.iso8601(6)
    }
  end

  def serialize_daily_page(page)
    {
      source_id: page.date.iso8601,
      date: page.date.iso8601
    }
  end

  def serialize_note(note)
    {
      source_id: note.id.to_s,
      body: note.body,
      notable_type: note.notable_type,
      notable_source_id: source_id_for_notable(note.notable),
      created_at: note.created_at.iso8601(6)
    }
  end

  def serialize_chain(chain)
    {
      source_id: chain.id.to_s,
      title: chain.title,
      description: chain.description,
      emoji: chain.emoji,
      completed_at: chain.completed_at&.iso8601(6),
      created_at: chain.created_at.iso8601(6),
      items: chain.chain_items.map { |item| serialize_chain_item(item) }
    }
  end

  def serialize_chain_item(item)
    {
      source_id: item.id.to_s,
      title: item.title,
      description: item.description,
      position: item.position,
      completed_at: item.completed_at&.iso8601(6),
      target_project_source_id: item.target_project_id&.to_s,
      todo_source_id: item.todo_id&.to_s,
      created_at: item.created_at.iso8601(6)
    }
  end

  def source_id_for_notable(notable)
    notable.is_a?(DailyPage) ? notable.date.iso8601 : notable.id.to_s
  end
end
