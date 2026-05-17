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

    context "stale task banner" do
      it "shows the stale banner when user has todos 3+ days overdue" do
        create(:todo, :stale, user: user, title: "Old forgotten task")
        get root_path
        expect(response.body).to include("stale-banner")
      end

      it "does not show the stale banner when overdue todos are less than 3 days old" do
        create(:todo, :overdue, user: user, title: "Slightly overdue task")
        get root_path
        expect(response.body).not_to include("stale-banner")
      end

      it "does not show the stale banner when there are no stale todos" do
        create(:todo, user: user, due_date: Date.current)
        get root_path
        expect(response.body).not_to include("stale-banner")
      end

      it "does not show the stale banner when viewing history" do
        create(:todo, :stale, user: user)
        get root_path(date: 7.days.ago.to_date.to_s)
        expect(response.body).not_to include("stale-banner")
      end
    end

    context "stale wizard" do
      it "embeds the wizard overlay in the page when stale todos exist" do
        create(:todo, :stale, user: user, title: "Long forgotten task")
        get root_path
        expect(response.body).to include("stale-wizard-overlay")
        expect(response.body).to include("Long forgotten task")
      end

      it "does not embed the wizard overlay when there are no stale todos" do
        get root_path
        expect(response.body).not_to include("stale-wizard-overlay")
      end
    end

    context "focus mode" do
      it "shows the focus mode button on today's page" do
        get root_path
        expect(response.body).to include("focus-mode-btn")
      end

      it "does not show the focus mode button when viewing history" do
        get root_path(date: 3.days.ago.to_date.to_s)
        expect(response.body).not_to include("focus-mode-btn")
      end

      it "embeds the focus panel with today's incomplete todos" do
        create(:todo, user: user, title: "Deep work block", due_date: Date.current)
        get root_path
        expect(response.body).to include("focus-panel")
        expect(response.body).to include("Deep work block")
      end

      it "embeds the focus view overlay with timer markup" do
        get root_path
        expect(response.body).to include("focus-view-overlay")
        expect(response.body).to include("focus-timer")
      end
    end
  end
end
