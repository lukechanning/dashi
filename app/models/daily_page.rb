class DailyPage < ApplicationRecord
  belongs_to :user
  has_many :notes, as: :notable, dependent: :destroy

  validates :date, presence: true, uniqueness: { scope: :user_id }

  def self.find_or_create_for(user, date = Date.current)
    find_or_create_by!(user: user, date: date)
  end

  def todos
    user.todos.due_on(date)
  end

  def overdue_todos
    user.todos.overdue(date)
  end

end
