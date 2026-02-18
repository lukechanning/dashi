class User < ApplicationRecord
  has_many :goals, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :todos, dependent: :destroy
  has_many :daily_pages, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :invitations, foreign_key: :invited_by_id, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email, with: ->(email) { email.strip.downcase }
end
