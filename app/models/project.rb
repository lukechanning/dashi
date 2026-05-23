class Project < ApplicationRecord
  include ActivityTrackable
  include MomentumTrackable

  belongs_to :user
  belongs_to :goal, optional: true
  has_many :todos, dependent: :destroy
  has_many :habits, dependent: :destroy
  has_many :notes, as: :notable, dependent: :destroy
  has_many :memberships, as: :memberable, dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_one :chain_item

  after_save :check_chain_completion, if: -> { saved_change_to_status? && completed? }

  enum :status, { active: 0, completed: 1, archived: 2 }

  validates :title, presence: true

  scope :ordered, -> { order(:position) }
  scope :standalone, -> { where(goal: nil) }

  private

  def check_chain_completion
    return unless (ci = chain_item)
    ci.complete!
    ci.chain.complete! if ci.chain.all_items_complete?
  end
end
