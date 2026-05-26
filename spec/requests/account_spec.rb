require "rails_helper"

RSpec.describe "Account", type: :request do
  let(:user) { create(:user) }

  describe "GET /account" do
    before { sign_in(user) }

    it "returns ok" do
      get account_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /account" do
    context "when authenticated" do
      before { sign_in(user) }

      it "updates show_stale_banner" do
        patch account_path, params: { user: { show_stale_banner: "0" } }
        expect(response).to redirect_to(account_path)
        expect(user.reload.show_stale_banner).to be false
      end

      it "updates show_reflection_banner" do
        patch account_path, params: { user: { show_reflection_banner: "0" } }
        expect(response).to redirect_to(account_path)
        expect(user.reload.show_reflection_banner).to be false
      end

      it "updates stale_threshold_days" do
        patch account_path, params: { user: { stale_threshold_days: "7" } }
        expect(response).to redirect_to(account_path)
        expect(user.reload.stale_threshold_days).to eq(7)
      end

      it "updates week_start_day to Sunday" do
        patch account_path, params: { user: { week_start_day: "0" } }
        expect(response).to redirect_to(account_path)
        expect(user.reload.week_start_day).to eq(0)
      end

      it "rejects an invalid stale_threshold_days" do
        patch account_path, params: { user: { stale_threshold_days: "99" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(user.reload.stale_threshold_days).to eq(3)
      end

      it "rejects an invalid week_start_day" do
        patch account_path, params: { user: { week_start_day: "6" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(user.reload.week_start_day).to eq(1)
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        patch account_path, params: { user: { show_stale_banner: "0" } }
        expect(response).to be_redirect
      end
    end
  end
end
