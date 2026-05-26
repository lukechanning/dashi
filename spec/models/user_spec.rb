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

  describe "#create_session!" do
    it "creates a new UserSession with a token" do
      user = create(:user)
      session = user.create_session!
      expect(session).to be_persisted
      expect(session.token).to be_present
      expect(session.user).to eq(user)
    end
  end

  describe "#activity_weeks" do
    let(:user) { create(:user) }

    it "returns 16 columns of 7 cells each" do
      result = user.activity_weeks
      expect(result[:columns].length).to eq(16)
      expect(result[:columns].first.length).to eq(7)
    end

    it "aggregates todos across all user projects for today's cell" do
      project1 = create(:project, user: user)
      project2 = create(:project, user: user)
      today = Date.current
      create_list(:todo, 2, :completed, user: user, project: project1,
                  completed_at: today.beginning_of_day + 1.hour)
      create(:todo, :completed, user: user, project: project2,
             completed_at: today.beginning_of_day + 2.hours)
      result = user.activity_weeks
      today_cell = result[:columns].flatten.find { |c| c[:date] == today }
      expect(today_cell[:count]).to eq(3)
    end

    it "marks future cells with future: true" do
      result = user.activity_weeks
      future_cells = result[:columns].flatten.select { |c| c[:future] }
      expect(future_cells).to all(include(future: true))
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

  describe "preferences" do
    let(:user) { create(:user) }

    describe "defaults" do
      it "defaults show_stale_banner to true" do
        expect(user.show_stale_banner).to be true
      end

      it "defaults show_reflection_banner to true" do
        expect(user.show_reflection_banner).to be true
      end

      it "defaults stale_threshold_days to 3" do
        expect(user.stale_threshold_days).to eq(3)
      end

      it "defaults week_start_day to 1 (Monday)" do
        expect(user.week_start_day).to eq(1)
      end
    end

    describe "#week_start_day_sym" do
      it "returns :monday when week_start_day is 1" do
        user.week_start_day = 1
        expect(user.week_start_day_sym).to eq(:monday)
      end

      it "returns :sunday when week_start_day is 0" do
        user.week_start_day = 0
        expect(user.week_start_day_sym).to eq(:sunday)
      end
    end

    describe "validations" do
      it "rejects stale_threshold_days outside allowed options" do
        user.stale_threshold_days = 10
        expect(user).not_to be_valid
        expect(user.errors[:stale_threshold_days]).to be_present
      end

      it "accepts all valid stale_threshold_days options" do
        User::STALE_THRESHOLD_OPTIONS.each do |days|
          user.stale_threshold_days = days
          expect(user).to be_valid
        end
      end

      it "rejects week_start_day outside allowed options" do
        user.week_start_day = 3
        expect(user).not_to be_valid
        expect(user.errors[:week_start_day]).to be_present
      end

      it "accepts week_start_day of 0 or 1" do
        [ 0, 1 ].each do |day|
          user.week_start_day = day
          expect(user).to be_valid
        end
      end
    end
  end
end
