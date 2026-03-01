class Todo < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :habit, optional: true
  has_many :notes, as: :notable, dependent: :destroy

  validates :title, presence: true

  scope :ordered, -> { order(:position) }
  scope :complete, -> { where.not(completed_at: nil) }
  scope :incomplete, -> { where(completed_at: nil) }
  scope :due_on, ->(date) { where(due_date: date) }
  scope :overdue, ->(date = Date.current) { incomplete.where(due_date: ...date) }
  scope :completed_on, ->(date) { complete.where(completed_at: date.beginning_of_day..date.end_of_day) }
  scope :visible_on, ->(date) {
    regular = where(habit_id: nil).incomplete
                .where("due_date IS NULL OR due_date <= ?", date)
    from_habits = where.not(habit_id: nil).incomplete.due_on(date)
    regular.or(from_habits).or(completed_on(date))
  }
  scope :standalone, -> { where(project: nil) }

  def complete!
    update!(completed_at: Time.current)
  end

  def incomplete!
    update!(completed_at: nil)
  end

  def complete?
    completed_at.present?
  end

  def from_habit?
    habit_id.present?
  end
end
