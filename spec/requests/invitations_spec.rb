require 'rails_helper'

RSpec.describe "Invitations", type: :request do
  describe "admin actions" do
    let(:admin) { create(:user, :admin) }

    before { sign_in(admin) }

    describe "GET /invitations" do
      it "lists invitations" do
        create(:invitation, invited_by: admin, email: "friend@example.com")
        get invitations_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("friend@example.com")
      end
    end

    describe "POST /invitations" do
      it "creates an invitation and sends an email" do
        expect {
          post invitations_path, params: { invitation: { email: "new@example.com" } }
        }.to change(Invitation, :count).by(1)
           .and have_enqueued_mail(InvitationMailer, :invite)

        expect(response).to redirect_to(invitations_path)
      end
    end
  end

  describe "non-admin access" do
    let(:user) { create(:user) }

    before { sign_in(user) }

    it "redirects from invitations index" do
      get invitations_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects from new invitation" do
      get new_invitation_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "accepting an invitation" do
    let(:invitation) { create(:invitation) }

    describe "GET /invitations/:token/accept" do
      it "shows the registration form" do
        get accept_invitation_path(token: invitation.token)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(invitation.email)
      end
    end

    describe "POST /invitations/:token/register" do
      it "creates a user and signs them in" do
        # invitation factory creates the invited_by user, so we reference it first
        invitation
        expect {
          post register_invitation_path(token: invitation.token), params: { user: { name: "New User" } }
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(root_path)
        expect(invitation.reload).to be_accepted

        new_user = User.find_by(email: invitation.email)
        expect(new_user.name).to eq("New User")
      end

      it "rejects registration without a name" do
        post register_invitation_path(token: invitation.token), params: { user: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
