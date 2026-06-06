class Chain < ApplicationRecord
  include SoftDeletable

  belongs_to :user
  has_many :chain_items, -> { order(:position) }, dependent: :destroy

  accepts_nested_attributes_for :chain_items

  validates :title, presence: true

  # Returns the ChainItem that comes immediately after the given one (by position).
  def next_item_after(chain_item)
    chain_items.find_by("position > ?", chain_item.position)
  end

  # True when every item in the chain has been completed.
  # Uses a DB query to avoid stale in-memory association cache.
  def all_items_complete?
    chain_items.where(completed_at: nil).none?
  end

  def complete!
    update!(completed_at: Time.current)
  end

  def complete?
    completed_at.present?
  end
end
