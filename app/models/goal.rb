class Goal < ApplicationRecord
  belongs_to :user
  has_many :projects, dependent: :destroy
  has_many :notes, as: :notable, dependent: :destroy

  enum :status, { active: 0, completed: 1, archived: 2 }

  validates :title, presence: true

  scope :ordered, -> { order(:position) }
end
