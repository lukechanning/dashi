require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:goals).dependent(:destroy) }
    it { should have_many(:projects).dependent(:destroy) }
    it { should have_many(:todos).dependent(:destroy) }
    it { should have_many(:daily_pages).dependent(:destroy) }
    it { should have_many(:notes).dependent(:destroy) }
    it { should have_many(:invitations).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:name) }
  end

  describe "normalizations" do
    it "downcases and strips email" do
      user = create(:user, email: "  Luke@Example.COM  ")
      expect(user.email).to eq("luke@example.com")
    end
  end

  describe "#generate_magic_token!" do
    it "sets a magic token and expiration" do
      user = create(:user)
      freeze_time do
        token = user.generate_magic_token!
        expect(token).to be_present
        expect(user.magic_token).to eq(token)
        expect(user.magic_token_expires_at).to eq(15.minutes.from_now)
      end
    end
  end

  describe "#clear_magic_token!" do
    it "clears the magic token and expiration" do
      user = create(:user)
      user.generate_magic_token!
      user.clear_magic_token!
      expect(user.magic_token).to be_nil
      expect(user.magic_token_expires_at).to be_nil
    end
  end

  describe "#magic_token_valid?" do
    it "returns true when token exists and is not expired" do
      user = create(:user)
      user.generate_magic_token!
      expect(user.magic_token_valid?).to be true
    end

    it "returns false when token is expired" do
      user = create(:user)
      user.generate_magic_token!
      travel_to 16.minutes.from_now do
        expect(user.magic_token_valid?).to be false
      end
    end

    it "returns false when token is nil" do
      user = create(:user)
      expect(user.magic_token_valid?).to be false
    end
  end

  describe "#reset_session_token!" do
    it "generates and persists a new session token" do
      user = create(:user)
      token = user.reset_session_token!
      expect(token).to be_present
      expect(user.reload.session_token).to eq(token)
    end
  end

  describe ".find_by_magic_token" do
    it "returns user with a valid token" do
      user = create(:user)
      token = user.generate_magic_token!
      expect(User.find_by_magic_token(token)).to eq(user)
    end

    it "returns nil for an expired token" do
      user = create(:user)
      token = user.generate_magic_token!
      travel_to 16.minutes.from_now do
        expect(User.find_by_magic_token(token)).to be_nil
      end
    end

    it "returns nil for a blank token" do
      expect(User.find_by_magic_token("")).to be_nil
      expect(User.find_by_magic_token(nil)).to be_nil
    end

    it "returns nil for a nonexistent token" do
      expect(User.find_by_magic_token("bogus")).to be_nil
    end
  end
end
