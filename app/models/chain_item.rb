class ChainItem < ApplicationRecord
  belongs_to :chain
  belongs_to :todo, optional: true
  belongs_to :project, optional: true

  validates :title, presence: true
  validates :item_type, inclusion: { in: %w[todo project] }
  validate :not_linked_to_both

  def activated?
    todo_id.present? || project_id.present?
  end

  def complete?
    completed_at.present?
  end

  def complete!
    update!(completed_at: Time.current)
  end

  private

  def not_linked_to_both
    if todo_id.present? && project_id.present?
      errors.add(:base, "cannot link to both a todo and a project")
    end
  end
end
