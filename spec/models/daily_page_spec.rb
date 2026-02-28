require 'rails_helper'

RSpec.describe DailyPage, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:notes).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:daily_page) }

    it { should validate_presence_of(:date) }
    it { should validate_uniqueness_of(:date).scoped_to(:user_id) }
  end

  describe ".find_or_create_for" do
    it "creates a new daily page for the user and date" do
      user = create(:user)
      page = DailyPage.find_or_create_for(user, Date.current)

      expect(page).to be_persisted
      expect(page.user).to eq(user)
      expect(page.date).to eq(Date.current)
    end

    it "returns an existing daily page" do
      user = create(:user)
      existing = create(:daily_page, user: user, date: Date.current)
      found = DailyPage.find_or_create_for(user, Date.current)

      expect(found).to eq(existing)
    end
  end

  describe "#todos" do
    it "returns todos due on the page's date" do
      user = create(:user)
      page = create(:daily_page, user: user, date: Date.current)
      today_todo = create(:todo, user: user, due_date: Date.current)
      _tomorrow_todo = create(:todo, user: user, due_date: Date.tomorrow)

      expect(page.todos).to eq([ today_todo ])
    end
  end

  describe "#history_todos" do
    let(:user) { create(:user) }
    let(:date) { Date.current - 1 }
    let(:page) { create(:daily_page, user: user, date: date) }

    it "includes todos completed on that date" do
      todo = create(:todo, user: user, due_date: date)
      todo.update!(completed_at: Time.zone.local(date.year, date.month, date.day, 12))

      expect(page.history_todos).to include(todo)
    end

    it "includes rolled-over todos completed on that date" do
      rolled_over = create(:todo, user: user, due_date: date - 3)
      rolled_over.update!(completed_at: Time.zone.local(date.year, date.month, date.day, 12))

      expect(page.history_todos).to include(rolled_over)
    end

    it "excludes todos completed on a different date" do
      next_date = date + 1
      completed_later = create(:todo, user: user, due_date: date)
      completed_later.update!(completed_at: Time.zone.local(next_date.year, next_date.month, next_date.day, 12))

      expect(page.history_todos).not_to include(completed_later)
    end

    it "excludes incomplete todos" do
      _incomplete = create(:todo, user: user, due_date: date)

      expect(page.history_todos).to be_empty
    end
  end

  describe "#overdue_todos" do
    it "returns incomplete todos from before the page's date" do
      user = create(:user)
      page = create(:daily_page, user: user, date: Date.current)
      overdue = create(:todo, user: user, due_date: 2.days.ago.to_date)
      _today = create(:todo, user: user, due_date: Date.current)
      _completed_overdue = create(:todo, :completed, user: user, due_date: 2.days.ago.to_date)

      expect(page.overdue_todos).to eq([ overdue ])
    end
  end
end
