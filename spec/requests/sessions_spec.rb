require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "GET /session/new" do
    it "renders the login page" do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session" do
    context "with a registered email" do
      it "sends a magic link email and redirects" do
        user = create(:user)
        expect {
          post session_path, params: { email: user.email }
        }.to have_enqueued_mail(SessionMailer, :magic_link)

        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(response.body).to include("sign-in link")
      end
    end

    context "with an unregistered email" do
      it "shows the same message but sends no email" do
        expect {
          post session_path, params: { email: "nobody@example.com" }
        }.not_to have_enqueued_mail(SessionMailer, :magic_link)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /auth/verify" do
    context "with a valid token" do
      it "signs in the user and redirects to root" do
        user = create(:user)
        token = user.generate_magic_token!

        get verify_session_path(token: token)

        expect(response).to redirect_to(root_path)
        expect(user.reload.magic_token).to be_nil
        expect(cookies[:session_token]).to be_present
      end
    end

    context "with an expired token" do
      it "redirects to login with an error" do
        user = create(:user)
        token = user.generate_magic_token!

        travel_to 16.minutes.from_now do
          get verify_session_path(token: token)
          expect(response).to redirect_to(new_session_path)
        end
      end
    end

    context "with an invalid token" do
      it "redirects to login with an error" do
        get verify_session_path(token: "bogus")
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /session" do
    it "signs out the user" do
      user = create(:user)
      token = user.generate_magic_token!
      get verify_session_path(token: token)

      delete session_path

      expect(response).to redirect_to(new_session_path)
      expect(user.reload.session_token).to be_nil
    end
  end

  describe "authentication required" do
    it "redirects unauthenticated users to login" do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
