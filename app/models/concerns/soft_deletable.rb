module SoftDeletable
  extend ActiveSupport::Concern

  included do
    default_scope { kept }

    scope :kept, -> { where(deleted_at: nil) }
    scope :deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
    scope :with_deleted, -> { unscope(where: :deleted_at) }
  end

  def discard!
    update!(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end
end
