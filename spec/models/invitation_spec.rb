require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe "associations" do
    it { should belong_to(:invited_by).class_name("User") }
  end

  describe "validations" do
    subject { build(:invitation) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:token) }
  end

  describe "normalizations" do
    it "downcases and strips email" do
      invitation = create(:invitation, email: "  Test@Example.COM  ")
      expect(invitation.email).to eq("test@example.com")
    end
  end

  describe "token generation" do
    it "generates a token before validation on create" do
      invitation = build(:invitation, token: nil)
      invitation.valid?
      expect(invitation.token).to be_present
    end

    it "does not overwrite an existing token" do
      invitation = build(:invitation, token: "custom-token")
      invitation.valid?
      expect(invitation.token).to eq("custom-token")
    end
  end

  describe "scopes" do
    it "returns pending invitations" do
      pending_inv = create(:invitation)
      _accepted = create(:invitation, accepted_at: Time.current)

      expect(Invitation.pending).to eq([pending_inv])
    end

    it "returns accepted invitations" do
      _pending = create(:invitation)
      accepted = create(:invitation, accepted_at: Time.current)

      expect(Invitation.accepted).to eq([accepted])
    end
  end

  describe "#accept!" do
    it "sets accepted_at" do
      invitation = create(:invitation)
      freeze_time do
        invitation.accept!
        expect(invitation.accepted_at).to eq(Time.current)
      end
    end
  end

  describe "#accepted?" do
    it "returns true when accepted" do
      expect(build(:invitation, accepted_at: Time.current)).to be_accepted
    end

    it "returns false when pending" do
      expect(build(:invitation)).not_to be_accepted
    end
  end
end
