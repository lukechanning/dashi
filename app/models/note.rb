class Note < ApplicationRecord
  belongs_to :notable, polymorphic: true
  belongs_to :user

  validates :body, presence: true

  scope :ordered, -> { order(created_at: :desc) }
end
