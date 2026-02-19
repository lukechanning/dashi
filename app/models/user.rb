class User < ApplicationRecord
  MAGIC_TOKEN_TTL = 15.minutes

  has_many :goals, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :todos, dependent: :destroy
  has_many :daily_pages, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :invitations, foreign_key: :invited_by_id, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email, with: ->(email) { email.strip.downcase }

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

  def reset_session_token!
    update!(session_token: SecureRandom.urlsafe_base64(32))
    session_token
  end

  def self.find_by_magic_token(token)
    return nil if token.blank?
    user = find_by(magic_token: token)
    user if user&.magic_token_valid?
  end

  def activity_weeks(weeks = 16)
    today = Date.current
    days_since_monday = today.wday == 0 ? 6 : today.wday - 1
    oldest_monday = today - days_since_monday - (weeks - 1).weeks

    counts = todos
      .where(completed_at: oldest_monday.beginning_of_day..)
      .group("DATE(completed_at)")
      .count

    columns = (0...weeks).map do |w|
      (0...7).map do |d|
        date = oldest_monday + (w * 7) + d
        { date: date, count: counts[date.to_s] || 0, future: date > today }
      end
    end

    month_labels = {}
    columns.each_with_index do |week, wi|
      monday = week[0][:date]
      if wi == 0 || monday.month != columns[wi - 1][0][:date].month
        month_labels[wi] = monday.strftime("%b")
      end
    end

    { columns: columns, month_labels: month_labels }
  end
end
