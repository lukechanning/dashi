require 'rails_helper'

RSpec.describe "Calendar", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /calendar" do
    it "renders the current month" do
      get calendar_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Date.current.strftime("%B %Y"))
    end

    it "respects the month param" do
      get calendar_path(month: "2026-06")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("June 2026")
    end

    it "shows completion indicators for days with completed todos" do
      create(:todo, :completed, user: user, due_date: Date.current)
      get calendar_path
      expect(response.body).to include("bg-emerald-400")
    end

    it "does not show indicators for incomplete todos" do
      create(:todo, user: user, due_date: Date.current)
      get calendar_path
      expect(response.body).not_to include("bg-emerald-400")
    end

    it "contains prev/next month navigation links" do
      get calendar_path
      prev_month = Date.current.beginning_of_month - 1.month
      next_month = Date.current.beginning_of_month + 1.month
      expect(response.body).to include(calendar_path(month: prev_month.strftime("%Y-%m")))
      expect(response.body).to include(calendar_path(month: next_month.strftime("%Y-%m")))
    end

    it "links day cells to the daily page" do
      get calendar_path
      expect(response.body).to include(root_path)
    end

    it "wraps content in a turbo frame" do
      get calendar_path
      expect(response.body).to include('id="calendar"')
    end
  end
end
