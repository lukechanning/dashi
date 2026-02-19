class Goal < ApplicationRecord
  include ActivityTrackable
  include MomentumTrackable

  belongs_to :user
  has_many :projects, dependent: :destroy
  has_many :todos, through: :projects
  has_many :notes, as: :notable, dependent: :destroy
  has_many :memberships, as: :memberable, dependent: :destroy
  has_many :members, through: :memberships, source: :user

  enum :status, { active: 0, completed: 1, archived: 2 }

  validates :title, presence: true

  scope :ordered, -> { order(:position) }
end
