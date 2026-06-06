class Project < ApplicationRecord
  include ActivityTrackable
  include MomentumTrackable
  include SoftDeletable

  belongs_to :user
  belongs_to :goal, optional: true
  has_many :todos, dependent: :destroy
  has_many :habits, dependent: :destroy
  has_many :notes, as: :notable, dependent: :destroy
  has_many :memberships, as: :memberable, dependent: :destroy
  has_many :members, through: :memberships, source: :user

  enum :status, { active: 0, completed: 1, archived: 2 }

  validates :title, presence: true

  scope :ordered, -> { order(:position) }
  scope :standalone, -> { where(goal: nil) }

  def discard!
    transaction do
      todos.find_each(&:discard!)
      habits.find_each(&:discard!)
      notes.find_each(&:discard!)
      super
    end
  end
end
