class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :memberable, polymorphic: true

  enum :role, { member: 0, admin: 1 }

  validates :user_id, uniqueness: { scope: [:memberable_type, :memberable_id], message: "is already a member" }
end
