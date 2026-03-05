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
    Current.user = token.present? ? UserSession.find_by(token: token)&.user : nil
  end

  def signed_in?
    current_user.present?
  end

  def sign_in(user)
    session = user.create_session!
    cookies.signed.permanent[:session_token] = { value: session.token, httponly: true, same_site: :lax }
    Current.user = user
  end

  def sign_out
    token = cookies.signed[:session_token]
    UserSession.find_by(token: token)&.destroy
    cookies.delete(:session_token)
    Current.user = nil
  end
end
