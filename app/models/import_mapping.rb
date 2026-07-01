class ImportMapping < ApplicationRecord
  belongs_to :user

  validates :source_account_key, :record_type, :source_id, :target_type, :target_id, presence: true
  validates :source_id, uniqueness: { scope: [ :user_id, :source_account_key, :record_type ] }
end
