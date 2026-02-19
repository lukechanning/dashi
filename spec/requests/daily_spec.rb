require 'rails_helper'

RSpec.describe "Daily", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /" do
    it "shows the daily page" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Today")
    end

    it "shows today's todos" do
      create(:todo, user: user, title: "Run 5k", due_date: Date.current)
      get root_path
      expect(response.body).to include("Run 5k")
    end

    it "does not show tomorrow's todos" do
      create(:todo, user: user, title: "Tomorrow thing", due_date: Date.tomorrow)
      get root_path
      expect(response.body).not_to include("Tomorrow thing")
    end

    it "shows past-due incomplete todos in the main list" do
      create(:todo, user: user, title: "Overdue task", due_date: 2.days.ago.to_date)
      get root_path
      expect(response.body).to include("Overdue task")
      expect(response.body).not_to include("Carried Over")
    end

    it "creates a daily page for the user" do
      expect { get root_path }.to change(DailyPage, :count).by(1)
    end
  end
end
