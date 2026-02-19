class Goal < ApplicationRecord
  belongs_to :user
  has_many :projects, dependent: :destroy
  has_many :todos, through: :projects
  has_many :notes, as: :notable, dependent: :destroy

  enum :status, { active: 0, completed: 1, archived: 2 }

  validates :title, presence: true

  scope :ordered, -> { order(:position) }

  MOMENTUM_WINDOW = 7.days

  def momentum
    return :new if todos.empty?
    count = todos.where(completed_at: MOMENTUM_WINDOW.ago..).count
    count >= 3 ? :hot : count >= 1 ? :warm : :cool
  end

  def momentum_label
    { hot: "Active", warm: "In progress", cool: "Gone quiet", new: "Just started" }[momentum]
  end

  def activity_weeks(weeks = 16)
    today = Date.current
    days_since_monday = today.wday == 0 ? 6 : today.wday - 1
    oldest_monday = today - days_since_monday - (weeks - 1).weeks

    counts = todos
      .where(completed_at: oldest_monday.beginning_of_day..)
      .group("DATE(completed_at)")
      .count

    columns = (0...weeks).map do |w|
      (0...7).map do |d|
        date = oldest_monday + (w * 7) + d
        { date: date, count: counts[date.to_s] || 0, future: date > today }
      end
    end

    month_labels = {}
    columns.each_with_index do |week, wi|
      monday = week[0][:date]
      if wi == 0 || monday.month != columns[wi - 1][0][:date].month
        month_labels[wi] = monday.strftime("%b")
      end
    end

    { columns: columns, month_labels: month_labels }
  end

  def weekly_activity(weeks = 12)
    today = Date.current
    days_since_monday = today.wday == 0 ? 6 : today.wday - 1
    current_monday = today - days_since_monday
    (0...weeks).map do |w|
      week_start = current_monday - (weeks - 1 - w).weeks
      week_end   = week_start + 6
      todos.where(completed_at: week_start.beginning_of_day..week_end.end_of_day).count
    end
  end
end
