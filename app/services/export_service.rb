class ExportService
  SCHEMA_VERSION = 2

  def initialize(user)
    @user = user
  end

  def call
    goals = user.goals.ordered.to_a
    projects = user.projects.ordered.to_a
    todos = user.todos.where(habit_id: nil).ordered.to_a
    habits = user.habits.ordered.to_a
    daily_pages = user.daily_pages.order(:date).to_a
    chains = user.chains.includes(chain_items: [ :target_project, :todo ]).order(:created_at).to_a

    @exported_goal_ids = goals.map { |goal| goal.id.to_s }.to_set
    @exported_project_ids = projects.map { |project| project.id.to_s }.to_set
    @exported_todo_ids = todos.map { |todo| todo.id.to_s }.to_set
    @exported_daily_page_ids = daily_pages.map { |page| page.date.iso8601 }.to_set
    notes = user.notes.order(:created_at).select { |note| exportable_note?(note) }

    {
      meta: {
        schema_version: SCHEMA_VERSION,
        export_id: SecureRandom.uuid,
        source_account_key: source_account_key,
        exported_at: Time.current.iso8601(6),
        user_email: user.email
      },
      preferences: serialize_preferences,
      goals: goals.map { |goal| serialize_goal(goal) },
      projects: projects.map { |project| serialize_project(project) },
      todos: todos.map { |todo| serialize_todo(todo) },
      habits: habits.map { |habit| serialize_habit(habit) },
      daily_pages: daily_pages.map { |page| serialize_daily_page(page) },
      notes: notes.map { |note| serialize_note(note) },
      chains: chains.map { |chain| serialize_chain(chain) }
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
      goal_source_id: exported_source_id(project.goal_id, @exported_goal_ids),
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
      project_source_id: exported_source_id(todo.project_id, @exported_project_ids),
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
      project_source_id: exported_source_id(habit.project_id, @exported_project_ids),
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
      target_project_source_id: exported_source_id(item.target_project_id, @exported_project_ids),
      todo_source_id: exported_source_id(item.todo_id, @exported_todo_ids),
      created_at: item.created_at.iso8601(6)
    }
  end

  def source_id_for_notable(notable)
    notable.is_a?(DailyPage) ? notable.date.iso8601 : notable.id.to_s
  end

  def exported_source_id(id, exported_ids)
    source_id = id&.to_s
    source_id if source_id.present? && exported_ids.include?(source_id)
  end

  def exportable_note?(note)
    case note.notable_type
    when "Goal"
      @exported_goal_ids.include?(note.notable_id.to_s)
    when "Project"
      @exported_project_ids.include?(note.notable_id.to_s)
    when "Todo"
      @exported_todo_ids.include?(note.notable_id.to_s)
    when "DailyPage"
      notable = note.notable
      notable.present? && @exported_daily_page_ids.include?(notable.date.iso8601)
    else
      false
    end
  end
end
