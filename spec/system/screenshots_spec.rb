# Run via: bin/screenshots
# Screenshots are saved to screenshots/ (gitignored)
require "rails_helper"

RSpec.describe "App Screenshots", type: :system do
  let!(:user) { create(:user, name: "Gandalf", email: "gandalf@istari.me") }

  # Goals — mix of active + one completed
  let!(:goal_ring)    { create(:goal, user:, title: "Destroy the One Ring",    status: :active) }
  let!(:goal_defend)  { create(:goal, user:, title: "Defend Middle-earth",     status: :active) }
  let!(:goal_wisdom)  { create(:goal, user:, title: "Master the Istari Arts",  status: :active) }
  let!(:goal_done)    { create(:goal, user:, title: "Recruit Bilbo Baggins",   status: :completed) }

  # Projects under "Destroy the One Ring" — one completed, one active
  let!(:proj_fellowship) do
    create(:project, user:, goal: goal_ring, title: "Assemble the Fellowship",
           status: :completed,
           description: "Gather representatives of the Free Peoples.")
  end
  let!(:proj_mordor) do
    create(:project, user:, goal: goal_ring, title: "Journey to Mount Doom",
           status: :active,
           description: "Navigate Moria, Rohan, and into Mordor itself.")
  end

  # Projects under "Defend Middle-earth"
  let!(:proj_rohan) do
    create(:project, user:, goal: goal_defend, title: "Save Rohan",
           status: :active,
           description: "Free Théoden and hold Helm's Deep.")
  end
  let!(:proj_gondor) do
    create(:project, user:, goal: goal_defend, title: "Rally Gondor",
           status: :active,
           description: "Light the beacons. Prepare Minas Tirith for siege.")
  end

  # Project under "Master the Istari Arts" — standalone-ish
  let!(:proj_pipeweed) do
    create(:project, user:, goal: goal_wisdom, title: "Pipeweed Research",
           status: :archived,
           description: "A wizard's secondary scholarly pursuit.")
  end

  # --- Todos: completed at various past times (heatmap fodder) ---
  let!(:t_council) do
    create(:todo, :completed, user:, project: proj_fellowship,
           title: "Convene the Council of Elrond",
           due_date: 14.days.ago.to_date, completed_at: 14.days.ago)
  end
  let!(:t_nine) do
    create(:todo, :completed, user:, project: proj_fellowship,
           title: "Name the Nine Walkers",
           due_date: 12.days.ago.to_date, completed_at: 12.days.ago)
  end
  let!(:t_moria_route) do
    create(:todo, :completed, user:, project: proj_fellowship,
           title: "Chart a route through Moria",
           due_date: 10.days.ago.to_date, completed_at: 10.days.ago)
  end
  let!(:t_boromir) do
    create(:todo, :completed, user:, project: proj_fellowship,
           title: "Convince Boromir this isn't a weapon",
           due_date: 8.days.ago.to_date, completed_at: 7.days.ago)
  end
  let!(:t_theoden) do
    create(:todo, :completed, user:, project: proj_rohan,
           title: "Break Saruman's hold on Théoden",
           due_date: 5.days.ago.to_date, completed_at: 5.days.ago)
  end
  let!(:t_helmsdeep) do
    create(:todo, :completed, user:, project: proj_rohan,
           title: "Survive Helm's Deep (somehow)",
           due_date: 3.days.ago.to_date, completed_at: 3.days.ago)
  end
  let!(:t_beacons) do
    create(:todo, :completed, user:, project: proj_gondor,
           title: "Light the beacons of Gondor",
           due_date: 2.days.ago.to_date, completed_at: 2.days.ago)
  end
  let!(:t_pipeweed_stock) do
    create(:todo, :completed, user:,
           title: "Restock pipeweed supply (personal)",
           due_date: 1.day.ago.to_date, completed_at: 1.day.ago)
  end

  # --- Todos: overdue (carryover candidates) ---
  let!(:t_gollum) do
    create(:todo, user:, project: proj_mordor,
           title: "Resolve the Gollum situation",
           due_date: 3.days.ago.to_date)
  end
  let!(:t_saruman) do
    create(:todo, user:, project: proj_rohan,
           title: "Deal with Saruman at Isengard",
           due_date: 2.days.ago.to_date)
  end

  # --- Todos: due today ---
  let!(:t_balrog) do
    create(:todo, user:, project: proj_mordor,
           title: "Avoid getting killed by the Balrog")
  end
  let!(:t_shelob) do
    create(:todo, user:, project: proj_mordor,
           title: "Warn Frodo about Shelob's lair")
  end
  let!(:t_denethor) do
    create(:todo, user:, project: proj_gondor,
           title: "Stop Denethor doing something rash")
  end
  let!(:t_eagle) do
    create(:todo, user:,
           title: "Send eagle to check on Frodo")
  end
  let!(:t_done_today) do
    create(:todo, :completed, user:, project: proj_mordor,
           title: "Pack lembas bread for the journey",
           completed_at: 2.hours.ago)
  end

  # --- Todos: future (upcoming view) ---
  let!(:t_shire) do
    create(:todo, user:,
           title: "Return the hobbits safely to the Shire",
           due_date: 3.days.from_now.to_date)
  end
  let!(:t_scouring) do
    create(:todo, user:, project: proj_rohan,
           title: "Address the Scouring of the Shire",
           due_date: 5.days.from_now.to_date)
  end
  let!(:t_crown) do
    create(:todo, user:, project: proj_gondor,
           title: "Oversee Aragorn's coronation logistics",
           due_date: 7.days.from_now.to_date)
  end
  let!(:t_grey_havens) do
    create(:todo, user:,
           title: "Book passage from the Grey Havens",
           due_date: 14.days.from_now.to_date)
  end

  # --- Habits ---
  let!(:habit_smoke)  { create(:habit, user:, title: "Smoke a pipe and think deeply", frequency: :daily) }
  let!(:habit_staff)  { create(:habit, user:, title: "Practice staff techniques", frequency: :custom, days_of_week: "1,3,5") }
  let!(:habit_eagles) { create(:habit, user:, title: "Check in with the Eagles", frequency: :weekdays) }
  let!(:habit_maps)   { create(:habit, user:, title: "Study ancient maps", frequency: :daily) }

  before do
    token = user.generate_magic_token!
    driven_by :screenshot_desktop
    visit verify_session_path(token: token)
  end

  it "daily page — desktop" do
    visit root_path
    page.save_screenshot("daily_desktop.png")
  end

  it "goals index — desktop" do
    visit goals_path
    page.save_screenshot("goals_desktop.png")
  end

  it "projects index — desktop" do
    visit projects_path
    page.save_screenshot("projects_desktop.png")
  end

  it "habits index — desktop" do
    visit habits_path
    page.save_screenshot("habits_desktop.png")
  end

  it "upcoming — desktop" do
    visit upcoming_path
    page.save_screenshot("upcoming_desktop.png")
  end

  it "daily page — mobile" do
    driven_by :screenshot_mobile
    token = user.generate_magic_token!
    visit verify_session_path(token: token)
    visit root_path
    page.save_screenshot("daily_mobile.png")
  end

  it "goals index — mobile" do
    driven_by :screenshot_mobile
    token = user.generate_magic_token!
    visit verify_session_path(token: token)
    visit goals_path
    page.save_screenshot("goals_mobile.png")
  end

  it "projects index — mobile" do
    driven_by :screenshot_mobile
    token = user.generate_magic_token!
    visit verify_session_path(token: token)
    visit projects_path
    page.save_screenshot("projects_mobile.png")
  end

  it "habits index — mobile" do
    driven_by :screenshot_mobile
    token = user.generate_magic_token!
    visit verify_session_path(token: token)
    visit habits_path
    page.save_screenshot("habits_mobile.png")
  end
end
