class ImportService
  Result = Data.define(:created, :skipped, :errors)
  ImportError = Class.new(StandardError)

  COLLECTIONS = %w[goals projects todos habits daily_pages notes chains].freeze
  NOTE_TYPES = %w[Goal Project Todo DailyPage].freeze
  PREFERENCE_KEYS = %w[
    timezone
    week_start_day
    appearance_theme
    stale_threshold_days
    show_stale_banner
    show_reflection_banner
  ].freeze

  def initialize(user, data)
    @user = user
    @data = data
    @created = 0
    @skipped = 0
    @records = Hash.new { |hash, key| hash[key] = {} }
  end

  def call
    payload = normalize_payload
    validate_payload!(payload)

    ActiveRecord::Base.transaction do
      import_preferences(payload["preferences"])
      import_goals(payload["goals"], payload)
      import_projects(payload["projects"], payload)
      import_todos(payload["todos"], payload)
      import_habits(payload["habits"], payload)
      import_daily_pages(payload["daily_pages"], payload)
      import_notes(payload["notes"], payload)
      import_chains(payload["chains"], payload)
    end

    Result.new(created: @created, skipped: @skipped, errors: [])
  rescue ImportError, ActiveRecord::RecordInvalid, ArgumentError => e
    Result.new(created: 0, skipped: 0, errors: [ e.message ])
  rescue => e
    Result.new(created: 0, skipped: 0, errors: [ e.message ])
  end

  private

  attr_reader :user

  def normalize_payload
    raise ImportError, "Invalid data format" unless @data.is_a?(Hash)
    raise ImportError, "Missing meta section" unless @data["meta"].is_a?(Hash)

    schema_version = @data.dig("meta", "schema_version")
    return normalize_v1(@data) if schema_version.blank? || schema_version.to_i == 1
    return normalize_v2(@data) if schema_version.to_i == 2

    raise ImportError, "Unsupported schema_version #{schema_version}"
  end

  def normalize_v2(data)
    meta = data["meta"]
    (COLLECTIONS + [ "preferences" ]).each do |key|
      raise ImportError, "Missing top-level #{key}" unless data.key?(key)
    end
    raise ImportError, "Missing meta.source_account_key" if meta["source_account_key"].blank?
    raise ImportError, "Missing meta.user_email" if meta["user_email"].blank?

    {
      "meta" => {
        "schema_version" => 2,
        "source_account_key" => meta["source_account_key"],
        "user_email" => meta["user_email"],
        "exported_at" => meta["exported_at"]
      },
      "preferences" => data["preferences"] || {},
      "goals" => Array(data["goals"]),
      "projects" => Array(data["projects"]),
      "todos" => Array(data["todos"]),
      "habits" => Array(data["habits"]),
      "daily_pages" => Array(data["daily_pages"]),
      "notes" => Array(data["notes"]),
      "chains" => Array(data["chains"])
    }
  end

  def normalize_v1(data)
    payload = {
      "meta" => {
        "schema_version" => 1,
        "source_account_key" => "legacy:#{data.dig("meta", "user_email")}",
        "user_email" => data.dig("meta", "user_email"),
        "exported_at" => data.dig("meta", "exported_at")
      },
      "preferences" => {},
      "goals" => [],
      "projects" => [],
      "todos" => [],
      "habits" => [],
      "daily_pages" => [],
      "notes" => [],
      "chains" => []
    }

    Array(data["goals"]).each do |goal|
      goal_source_id = source_id(goal, "goal")
      payload["goals"] << goal.slice("title", "description", "emoji", "status", "position", "created_at").merge("source_id" => goal_source_id)
      nested_notes(payload, goal["notes"], "Goal", goal_source_id)

      Array(goal["projects"]).each do |project|
        project_source_id = source_id(project, "project")
        payload["projects"] << project.slice("title", "description", "emoji", "status", "position", "created_at").merge(
          "source_id" => project_source_id,
          "goal_source_id" => goal_source_id
        )
        nested_notes(payload, project["notes"], "Project", project_source_id)

        Array(project["todos"]).each do |todo|
          todo_source_id = source_id(todo, "todo")
          payload["todos"] << todo.slice("title", "notes_text", "due_date", "completed_at", "position", "created_at").merge(
            "source_id" => todo_source_id,
            "project_source_id" => project_source_id
          )
          nested_notes(payload, todo["notes"], "Todo", todo_source_id)
        end

        Array(project["habits"]).each do |habit|
          payload["habits"] << habit.slice("title", "frequency", "days_of_week", "active", "start_date", "position", "created_at").merge(
            "source_id" => source_id(habit, "habit"),
            "project_source_id" => project_source_id
          )
        end
      end
    end

    Array(data["standalone_todos"]).each do |todo|
      todo_source_id = source_id(todo, "todo")
      payload["todos"] << todo.slice("title", "notes_text", "due_date", "completed_at", "position", "created_at").merge(
        "source_id" => todo_source_id,
        "project_source_id" => nil
      )
      nested_notes(payload, todo["notes"], "Todo", todo_source_id)
    end

    Array(data["daily_pages"]).each do |page|
      page_source_id = page["date"].to_s
      payload["daily_pages"] << { "source_id" => page_source_id, "date" => page["date"] }
      nested_notes(payload, page["notes"], "DailyPage", page_source_id)
    end

    payload
  end

  def nested_notes(payload, notes, notable_type, notable_source_id)
    Array(notes).each do |note|
      payload["notes"] << note.slice("body", "created_at").merge(
        "source_id" => source_id(note, "note"),
        "notable_type" => notable_type,
        "notable_source_id" => notable_source_id
      )
    end
  end

  def source_id(data, fallback_type)
    (data["source_id"] || data["id"] || "#{fallback_type}:#{SecureRandom.uuid}").to_s
  end

  def validate_payload!(payload)
    COLLECTIONS.each do |collection|
      raise ImportError, "#{collection} must be an array" unless payload[collection].is_a?(Array)
      validate_duplicate_source_ids!(collection, payload[collection])
    end

    payload["goals"].each { |record| validate_goal!(record) }
    payload["projects"].each { |record| validate_project!(record, payload) }
    payload["todos"].each { |record| validate_todo!(record, payload) }
    payload["habits"].each { |record| validate_habit!(record, payload) }
    payload["daily_pages"].each { |record| validate_daily_page!(record) }
    payload["notes"].each { |record| validate_note!(record, payload) }
    payload["chains"].each { |record| validate_chain!(record, payload) }
    validate_preferences!(payload["preferences"])
  end

  def validate_duplicate_source_ids!(collection, records)
    seen = {}
    records.each do |record|
      validate_record_hash!(collection, record)
      id = required(record, "source_id", collection).to_s
      raise ImportError, "Duplicate source_id #{id} in #{collection}" if seen[id]
      seen[id] = true
    end
  end

  def validate_goal!(record)
    required(record, "title", "goals")
    validate_enum!(record, "status", Goal.statuses.keys, "goals")
    validate_time!(record["created_at"], "goals.created_at") if record["created_at"].present?
  end

  def validate_project!(record, payload)
    required(record, "title", "projects")
    validate_enum!(record, "status", Project.statuses.keys, "projects")
    validate_time!(record["created_at"], "projects.created_at") if record["created_at"].present?
    validate_reference!("projects.goal_source_id", "goals", record["goal_source_id"], payload) if record["goal_source_id"].present?
  end

  def validate_todo!(record, payload)
    required(record, "title", "todos")
    validate_date!(record["due_date"], "todos.due_date") if record["due_date"].present?
    validate_time!(record["completed_at"], "todos.completed_at") if record["completed_at"].present?
    validate_time!(record["created_at"], "todos.created_at") if record["created_at"].present?
    validate_reference!("todos.project_source_id", "projects", record["project_source_id"], payload) if record["project_source_id"].present?
  end

  def validate_habit!(record, payload)
    required(record, "title", "habits")
    validate_enum!(record, "frequency", Habit.frequencies.keys, "habits")
    validate_date!(record["start_date"], "habits.start_date") if record["start_date"].present?
    validate_time!(record["created_at"], "habits.created_at") if record["created_at"].present?
    validate_reference!("habits.project_source_id", "projects", record["project_source_id"], payload) if record["project_source_id"].present?
  end

  def validate_daily_page!(record)
    validate_date!(required(record, "date", "daily_pages"), "daily_pages.date")
  end

  def validate_note!(record, payload)
    required(record, "body", "notes")
    notable_type = required(record, "notable_type", "notes")
    raise ImportError, "Unsupported notable_type #{notable_type}" unless NOTE_TYPES.include?(notable_type)
    validate_reference!("notes.notable_source_id", collection_for_type(notable_type), required(record, "notable_source_id", "notes"), payload)
    validate_time!(record["created_at"], "notes.created_at") if record["created_at"].present?
  end

  def validate_chain!(record, payload)
    required(record, "title", "chains")
    validate_time!(record["completed_at"], "chains.completed_at") if record["completed_at"].present?
    validate_time!(record["created_at"], "chains.created_at") if record["created_at"].present?
    raise ImportError, "chains.items must be an array" unless Array(record["items"]).is_a?(Array)

    seen = {}
    Array(record["items"]).each do |item|
      validate_record_hash!("chain items", item)
      id = required(item, "source_id", "chain items").to_s
      raise ImportError, "Duplicate source_id #{id} in chain items" if seen[id]
      seen[id] = true
      required(item, "title", "chain items")
      required(item, "position", "chain items")
      validate_time!(item["completed_at"], "chain_items.completed_at") if item["completed_at"].present?
      validate_time!(item["created_at"], "chain_items.created_at") if item["created_at"].present?
      validate_reference!("chain_items.target_project_source_id", "projects", item["target_project_source_id"], payload) if item["target_project_source_id"].present?
      validate_reference!("chain_items.todo_source_id", "todos", item["todo_source_id"], payload) if item["todo_source_id"].present?
    end
  end

  def validate_preferences!(preferences)
    raise ImportError, "preferences must be an object" unless preferences.is_a?(Hash)
    return if preferences.empty?

    if preferences.key?("week_start_day") && !User::WEEK_START_SYMBOLS.key?(preferences["week_start_day"])
      raise ImportError, "Invalid week_start_day"
    end
    if preferences.key?("appearance_theme") && !User::APPEARANCE_THEME_OPTIONS.include?(preferences["appearance_theme"])
      raise ImportError, "Invalid appearance_theme"
    end
    if preferences.key?("stale_threshold_days") && !User::STALE_THRESHOLD_OPTIONS.include?(preferences["stale_threshold_days"])
      raise ImportError, "Invalid stale_threshold_days"
    end
  end

  def validate_record_hash!(collection, record)
    raise ImportError, "#{collection} records must be objects" unless record.is_a?(Hash)
  end

  def validate_reference!(field, collection, source_id, payload)
    return if payload[collection].any? { |record| record["source_id"].to_s == source_id.to_s }
    return if mapping_for(payload, record_type(collection), source_id)

    raise ImportError, "Unresolved reference #{field}=#{source_id}"
  end

  def required(record, key, collection)
    value = record[key]
    raise ImportError, "Missing required field #{collection}.#{key}" if value.nil? || (value.respond_to?(:empty?) && value.empty?)
    value
  end

  def validate_enum!(record, key, allowed, collection)
    value = record[key]
    raise ImportError, "Missing required field #{collection}.#{key}" if value.blank?
    raise ImportError, "Invalid #{collection}.#{key}" unless allowed.include?(value)
  end

  def validate_time!(value, field)
    Time.zone.parse(value.to_s) || raise(ImportError, "Invalid #{field}")
  rescue ArgumentError, TypeError
    raise ImportError, "Invalid #{field}"
  end

  def validate_date!(value, field)
    Date.iso8601(value.to_s)
  rescue ArgumentError, TypeError
    raise ImportError, "Invalid #{field}"
  end

  def import_preferences(preferences)
    attrs = preferences.slice(*PREFERENCE_KEYS)
    user.update!(attrs) if attrs.any?
  end

  def import_goals(records, payload)
    records.each do |record|
      import_record(payload, "Goal", record) do
        user.goals.create!(
          title: record["title"],
          description: record["description"],
          emoji: record["emoji"],
          status: record["status"],
          position: record["position"],
          created_at: parse_time(record["created_at"])
        )
      end
    end
  end

  def import_projects(records, payload)
    records.each do |record|
      import_record(payload, "Project", record) do
        user.projects.create!(
          title: record["title"],
          description: record["description"],
          emoji: record["emoji"],
          status: record["status"],
          position: record["position"],
          goal: resolve(payload, "Goal", record["goal_source_id"]),
          created_at: parse_time(record["created_at"])
        )
      end
    end
  end

  def import_todos(records, payload)
    records.each do |record|
      import_record(payload, "Todo", record) do
        todo = user.todos.build(
          title: record["title"],
          due_date: parse_date(record["due_date"]),
          completed_at: parse_time(record["completed_at"]),
          position: record["position"],
          project: resolve(payload, "Project", record["project_source_id"]),
          created_at: parse_time(record["created_at"])
        )
        todo.write_attribute(:notes, record["notes_text"])
        todo.save!
        todo
      end
    end
  end

  def import_habits(records, payload)
    records.each do |record|
      import_record(payload, "Habit", record) do
        user.habits.create!(
          title: record["title"],
          frequency: record["frequency"],
          days_of_week: record["days_of_week"],
          active: record.key?("active") ? record["active"] : true,
          start_date: parse_date(record["start_date"]),
          position: record["position"],
          project: resolve(payload, "Project", record["project_source_id"]),
          created_at: parse_time(record["created_at"])
        )
      end
    end
  end

  def import_daily_pages(records, payload)
    records.each do |record|
      import_record(payload, "DailyPage", record) do
        user.daily_pages.create!(date: parse_date(record["date"]))
      end
    end
  end

  def import_notes(records, payload)
    records.each do |record|
      import_record(payload, "Note", record) do
        notable = resolve(payload, record["notable_type"], record["notable_source_id"])
        notable.notes.create!(
          body: record["body"],
          user: user,
          created_at: parse_time(record["created_at"])
        )
      end
    end
  end

  def import_chains(records, payload)
    records.each do |record|
      chain = import_record(payload, "Chain", record) do
        user.chains.create!(
          title: record["title"],
          description: record["description"],
          emoji: record["emoji"],
          completed_at: parse_time(record["completed_at"]),
          created_at: parse_time(record["created_at"])
        )
      end

      Array(record["items"]).each do |item|
        import_chain_item(payload, chain, item)
      end
    end
  end

  def import_chain_item(payload, chain, item)
    source_id = item["source_id"].to_s
    if (mapped = mapped_record(payload, "ChainItem", source_id))
      @records["ChainItem"][source_id] = mapped
      @skipped += 1
      return mapped
    end

    if (matched = chain_item_fingerprint_match(chain, item))
      create_mapping!(payload, "ChainItem", source_id, matched)
      @records["ChainItem"][source_id] = matched
      @skipped += 1
      return matched
    end

    created = chain.chain_items.create!(
      title: item["title"],
      description: item["description"],
      position: item["position"],
      completed_at: parse_time(item["completed_at"]),
      target_project: resolve(payload, "Project", item["target_project_source_id"]),
      todo: resolve(payload, "Todo", item["todo_source_id"]),
      created_at: parse_time(item["created_at"])
    )
    create_mapping!(payload, "ChainItem", source_id, created)
    @records["ChainItem"][source_id] = created
    @created += 1
    created
  end

  def import_record(payload, type, record)
    source_id = record["source_id"].to_s
    if (mapped = mapped_record(payload, type, source_id))
      @records[type][source_id] = mapped
      @skipped += 1
      return mapped
    end

    if (matched = fingerprint_match(type, record, payload))
      create_mapping!(payload, type, source_id, matched)
      @records[type][source_id] = matched
      @skipped += 1
      return matched
    end

    created = yield
    create_mapping!(payload, type, source_id, created)
    @records[type][source_id] = created
    @created += 1
    created
  end

  def mapped_record(payload, type, source_id)
    mapping = mapping_for(payload, type, source_id)
    return unless mapping

    type.constantize.find_by(id: mapping.target_id)
  end

  def mapping_for(payload, type, source_id)
    return if source_id.blank?

    user.import_mappings.find_by(
      source_account_key: payload.dig("meta", "source_account_key"),
      record_type: type,
      source_id: source_id.to_s
    )
  end

  def create_mapping!(payload, type, source_id, target)
    user.import_mappings.find_or_create_by!(
      source_account_key: payload.dig("meta", "source_account_key"),
      record_type: type,
      source_id: source_id.to_s
    ) do |mapping|
      mapping.target_type = target.class.name
      mapping.target_id = target.id
    end
  end

  def resolve(payload, type, source_id)
    return nil if source_id.blank?
    return @records[type][source_id.to_s] if @records[type].key?(source_id.to_s)

    mapped_record(payload, type, source_id) || fingerprint_match_by_source(payload, type, source_id) ||
      raise(ImportError, "Unresolved reference #{type}=#{source_id}")
  end

  def fingerprint_match_by_source(payload, type, source_id)
    collection = collection_for_type(type)
    record = payload[collection].find { |item| item["source_id"].to_s == source_id.to_s }
    return unless record

    fingerprint_match(type, record, payload)
  end

  def fingerprint_match(type, record, payload)
    case type
    when "Goal"
      user.goals.find_by(title: record["title"], status: record["status"], created_at: parse_time(record["created_at"]))
    when "Project"
      user.projects.find_by(title: record["title"], status: record["status"], created_at: parse_time(record["created_at"]))
    when "Todo"
      user.todos.find_by(title: record["title"], due_date: parse_date(record["due_date"]), created_at: parse_time(record["created_at"]))
    when "Habit"
      user.habits.find_by(title: record["title"], frequency: record["frequency"], start_date: parse_date(record["start_date"]))
    when "DailyPage"
      user.daily_pages.find_by(date: parse_date(record["date"]))
    when "Note"
      notable = resolve(payload, record["notable_type"], record["notable_source_id"])
      notable.notes.find_by(body: record["body"], created_at: parse_time(record["created_at"]))
    when "Chain"
      user.chains.find_by(title: record["title"], created_at: parse_time(record["created_at"]))
    when "ChainItem"
      nil
    end
  end

  def record_type(collection)
    {
      "goals" => "Goal",
      "projects" => "Project",
      "todos" => "Todo",
      "habits" => "Habit",
      "daily_pages" => "DailyPage",
      "notes" => "Note",
      "chains" => "Chain"
    }.fetch(collection)
  end

  def collection_for_type(type)
    {
      "Goal" => "goals",
      "Project" => "projects",
      "Todo" => "todos",
      "Habit" => "habits",
      "DailyPage" => "daily_pages",
      "Note" => "notes",
      "Chain" => "chains"
    }.fetch(type)
  end

  def parse_time(value)
    value.present? ? Time.zone.parse(value.to_s) : nil
  end

  def parse_date(value)
    value.present? ? Date.iso8601(value.to_s) : nil
  end

  def chain_item_fingerprint_match(chain, item)
    chain.chain_items.find_by(
      position: item["position"],
      title: item["title"],
      created_at: parse_time(item["created_at"])
    )
  end
end
