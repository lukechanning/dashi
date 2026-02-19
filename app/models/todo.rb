class Todo < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true
  has_many :notes, as: :notable, dependent: :destroy

  validates :title, presence: true

  scope :ordered, -> { order(:position) }
  scope :complete, -> { where.not(completed_at: nil) }
  scope :incomplete, -> { where(completed_at: nil) }
  scope :due_on, ->(date) { where(due_date: date) }
  scope :overdue, ->(date = Date.current) { incomplete.where(due_date: ...date) }
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
end
