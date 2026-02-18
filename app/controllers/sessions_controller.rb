class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create, :verify]

  layout "auth"

  def new
  end

  def create
    user = User.find_by(email: User.normalize_value_for(:email, params[:email]))

    if user
      token = user.generate_magic_token!
      SessionMailer.magic_link(user, token).deliver_later
    end

    redirect_to new_session_path, notice: "If that email is registered, you'll receive a sign-in link shortly."
  end

  def verify
    user = User.find_by_magic_token(params[:token])

    if user
      user.clear_magic_token!
      sign_in(user)
      redirect_to root_path, notice: "Signed in successfully."
    else
      redirect_to new_session_path, alert: "Invalid or expired link. Please try again."
    end
  end

  def destroy
    sign_out
    redirect_to new_session_path, notice: "Signed out."
  end
end
