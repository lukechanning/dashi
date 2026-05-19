require 'rails_helper'

RSpec.describe "Account::Imports", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  def valid_export_json(user)
    {
      meta: { exported_at: Time.current.iso8601, user_email: user.email },
      goals: [],
      standalone_todos: [],
      daily_pages: []
    }.to_json
  end

  describe "GET /account/import/new" do
    it "renders the upload form" do
      get new_account_import_path
      expect(response).to have_http_status(:ok)
    end

    it "requires authentication" do
      delete session_path
      get new_account_import_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "POST /account/import" do
    context "with a valid export file" do
      it "redirects to the account page with a success flash" do
        file = Rack::Test::UploadedFile.new(
          StringIO.new(valid_export_json(user)),
          "application/json",
          original_filename: "export.json"
        )
        post account_import_path, params: { import: { file: file } }
        expect(response).to redirect_to(account_path)
        follow_redirect!
        expect(response.body).to include("Import complete")
      end
    end

    context "with no file uploaded" do
      it "re-renders the form with an error" do
        post account_import_path, params: { import: { file: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with invalid JSON" do
      it "re-renders the form with an error" do
        file = Rack::Test::UploadedFile.new(
          StringIO.new("not valid json"),
          "application/json",
          original_filename: "export.json"
        )
        post account_import_path, params: { import: { file: file } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with a file from a different user" do
      it "re-renders the form with an error" do
        other_export = {
          meta: { exported_at: Time.current.iso8601, user_email: "other@example.com" },
          goals: [],
          standalone_todos: [],
          daily_pages: []
        }.to_json
        file = Rack::Test::UploadedFile.new(
          StringIO.new(other_export),
          "application/json",
          original_filename: "export.json"
        )
        post account_import_path, params: { import: { file: file } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it "requires authentication" do
      delete session_path
      post account_import_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
