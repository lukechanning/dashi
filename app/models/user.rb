class User < ApplicationRecord
  include ActivityTrackable

  MAGIC_TOKEN_TTL = 15.minutes

  has_many :user_sessions, dependent: :destroy
  has_many :goals, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :todos, dependent: :destroy
  has_many :habits, dependent: :destroy
  has_many :daily_pages, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :invitations, foreign_key: :invited_by_id, dependent: :destroy
  has_many :chains, dependent: :destroy

  STALE_THRESHOLD_OPTIONS = [ 3, 5, 7, 14 ].freeze
  APPEARANCE_THEME_OPTIONS = %w[light dark].freeze
  # Array of [label, value] pairs — order determines dropdown display order
  WEEK_START_OPTIONS = [ [ "Monday", 1 ], [ "Sunday", 0 ] ].freeze
  WEEK_START_SYMBOLS  = { 0 => :sunday, 1 => :monday }.freeze

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :stale_threshold_days, inclusion: { in: STALE_THRESHOLD_OPTIONS }
  validates :week_start_day, inclusion: { in: WEEK_START_SYMBOLS.keys }
  validates :appearance_theme, inclusion: { in: APPEARANCE_THEME_OPTIONS }

  normalizes :email, with: ->(email) { email.strip.downcase }

  def week_start_day_sym
    WEEK_START_SYMBOLS.fetch(week_start_day, :monday)
  end

  def generate_habit_todos_for(date)
    habits.active.find_each do |habit|
      habit.generate_todo_for!(date)
    end
  end

  def generate_magic_token!
    update!(
      magic_token: SecureRandom.urlsafe_base64(32),
      magic_token_expires_at: MAGIC_TOKEN_TTL.from_now
    )
    magic_token
  end

  def clear_magic_token!
    update!(magic_token: nil, magic_token_expires_at: nil)
  end

  def magic_token_valid?
    magic_token.present? && magic_token_expires_at&.future?
  end

  def create_session!
    user_sessions.create!
  end

  def self.find_by_magic_token(token)
    return nil if token.blank?
    user = find_by(magic_token: token)
    user if user&.magic_token_valid?
  end
end
