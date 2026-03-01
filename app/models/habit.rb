class Habit < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true
  has_many :todos, dependent: :nullify

  enum :frequency, { daily: 0, weekdays: 1, custom: 2 }

  validates :title, presence: true
  validates :start_date, presence: true
  validates :days_of_week, presence: true, if: :custom?

  before_validation :set_default_start_date, on: :create

  scope :active, -> { where(active: true) }
  scope :paused, -> { where(active: false) }
  scope :ordered, -> { order(:position) }

  def scheduled_for?(date)
    return false unless active?
    return false if date < start_date

    case frequency
    when "daily"
      true
    when "weekdays"
      (1..5).cover?(date.wday)
    when "custom"
      parsed_days.include?(date.wday)
    end
  end

  def generate_todo_for!(date)
    return unless scheduled_for?(date)

    todos.find_or_create_by!(due_date: date) do |todo|
      todo.title = title
      todo.user = user
      todo.project = project
    end
  end

  def pause!
    update!(active: false)
  end

  def resume!
    update!(active: true)
  end

  def schedule_description
    case frequency
    when "daily"
      "Every day"
    when "weekdays"
      "Weekdays"
    when "custom"
      day_names = parsed_days.sort.map { |d| Date::ABBR_DAYNAMES[d] }
      day_names.join(", ")
    end
  end

  private

  def set_default_start_date
    self.start_date ||= Date.current
  end

  def parsed_days
    return [] if days_of_week.blank?
    days_of_week.split(",").map(&:to_i)
  end
end
