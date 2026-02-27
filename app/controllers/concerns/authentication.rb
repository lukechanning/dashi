module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    helper_method :current_user, :signed_in?
  end

  private

  def authenticate_user!
    redirect_to new_session_path, alert: "Please sign in to continue." unless signed_in?
  end

  def current_user
    return Current.user if Current.user
    token = cookies.signed[:session_token]
    Current.user = token.present? ? User.find_by(session_token: token) : nil
  end

  def signed_in?
    current_user.present?
  end

  def sign_in(user)
    token = user.reset_session_token!
    cookies.signed.permanent[:session_token] = { value: token, httponly: true, same_site: :lax }
    Current.user = user
  end

  def sign_out
    current_user&.update!(session_token: nil)
    cookies.delete(:session_token)
    Current.user = nil
  end
end
