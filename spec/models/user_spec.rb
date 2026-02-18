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
end
