require "rails_helper"

RSpec.describe "Dismissals", type: :request do
  let(:user) { create(:user) }

  describe "POST /dismissals" do
    context "when authenticated" do
      before { sign_in(user) }

      context "with a valid banner type" do
        it "returns 204 No Content for reflection" do
          post dismissals_path, params: { banner: "reflection" }
          expect(response).to have_http_status(:no_content)
        end

        it "returns 204 No Content for stale" do
          post dismissals_path, params: { banner: "stale" }
          expect(response).to have_http_status(:no_content)
        end

        it "sets a signed reflection_dismissed_on cookie" do
          post dismissals_path, params: { banner: "reflection" }
          expect(response.cookies["reflection_dismissed_on"]).to be_present
        end

        it "sets a signed stale_dismissed_on cookie" do
          post dismissals_path, params: { banner: "stale" }
          expect(response.cookies["stale_dismissed_on"]).to be_present
        end
      end

      context "with an invalid banner type" do
        it "returns 422 for an unknown banner" do
          post dismissals_path, params: { banner: "nonexistent" }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns 422 for an empty banner param" do
          post dismissals_path, params: { banner: "" }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when not authenticated" do
      it "redirects away (requires authentication)" do
        post dismissals_path, params: { banner: "reflection" }
        expect(response).to be_redirect
      end
    end
  end
end
