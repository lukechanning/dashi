class Goal < ApplicationRecord
  belongs_to :user
  has_many :projects, dependent: :destroy
  has_many :todos, through: :projects
  has_many :notes, as: :notable, dependent: :destroy

  enum :status, { active: 0, completed: 1, archived: 2 }

  validates :title, presence: true

  scope :ordered, -> { order(:position) }

  def progress
    all_todos = todos
    return 0 if all_todos.empty?
    (all_todos.where.not(completed_at: nil).count.to_f / all_todos.count * 100).round
  end
end
