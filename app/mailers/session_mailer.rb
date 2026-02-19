class SessionMailer < ApplicationMailer
  def magic_link(user, token)
    @user = user
    @url = verify_session_url(token: token)

    mail(to: user.email, subject: "Your Dashi sign-in link")
  end
end
