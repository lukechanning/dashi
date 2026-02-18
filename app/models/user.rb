class User < ApplicationRecord
  has_many :goals, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :todos, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email, with: ->(email) { email.strip.downcase }
end
