class Project < ApplicationRecord
  belongs_to :user
  belongs_to :goal, optional: true
  has_many :todos, dependent: :destroy
  has_many :notes, as: :notable, dependent: :destroy

  enum :status, { active: 0, completed: 1, archived: 2 }

  validates :title, presence: true

  scope :ordered, -> { order(:position) }
  scope :standalone, -> { where(goal: nil) }

  def progress
    return 0 if todos.empty?
    (todos.where.not(completed_at: nil).count.to_f / todos.count * 100).round
  end
end
