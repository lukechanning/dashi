if Rails.env.development?
  # Create the initial admin user
  admin = User.find_or_create_by!(email: "admin@example.com") do |user|
    user.name = "Gandalf"
    user.admin = true
  end

  puts "Admin user: #{admin.email} (admin: #{admin.admin?})"

  # --- Goal: Destroy the One Ring ---
  ring_goal = Goal.find_or_create_by!(user: admin, title: "Destroy the One Ring") do |g|
    g.description = "Cast the One Ring into the fires of Mount Doom and end Sauron's dominion over Middle-earth."
  end

  fellowship = Project.find_or_create_by!(user: admin, goal: ring_goal, title: "Assemble the Fellowship") do |p|
    p.description = "Gather representatives of the Free Peoples to escort the Ring-bearer."
  end

  Todo.find_or_create_by!(user: admin, project: fellowship, title: "Convene the Council of Elrond") do |t|
    t.due_date = Date.yesterday
    t.completed_at = 2.days.ago
  end

  Todo.find_or_create_by!(user: admin, project: fellowship, title: "Convince Boromir this isn't a weapon") do |t|
    t.due_date = Date.current
  end

  mordor = Project.find_or_create_by!(user: admin, goal: ring_goal, title: "Journey to Mount Doom") do |p|
    p.description = "Navigate through Moria, Rohan, and into Mordor itself."
  end

  Todo.find_or_create_by!(user: admin, project: mordor, title: "Find a way through the Mines of Moria") do |t|
    t.due_date = Date.current
  end

  Todo.find_or_create_by!(user: admin, project: mordor, title: "Avoid getting killed by the Balrog") do |t|
    t.due_date = Date.current
  end

  Todo.find_or_create_by!(user: admin, project: mordor, title: "Deal with Gollum situation") do |t|
    t.due_date = Date.tomorrow
  end

  # --- Goal: Defend Middle-earth ---
  defend_goal = Goal.find_or_create_by!(user: admin, title: "Defend Middle-earth") do |g|
    g.description = "Rally the kingdoms of Men, Elves, and Dwarves against the forces of darkness."
  end

  rohan = Project.find_or_create_by!(user: admin, goal: defend_goal, title: "Save Rohan") do |p|
    p.description = "Free Theoden from Saruman's influence and defend Helm's Deep."
  end

  Todo.find_or_create_by!(user: admin, project: rohan, title: "Break Saruman's hold on Theoden") do |t|
    t.due_date = Date.yesterday
  end

  Todo.find_or_create_by!(user: admin, project: rohan, title: "Ride to Helm's Deep") do |t|
    t.due_date = Date.current
  end

  gondor = Project.find_or_create_by!(user: admin, goal: defend_goal, title: "Rally Gondor") do |p|
    p.description = "Light the beacons and prepare Minas Tirith for siege."
  end

  Todo.find_or_create_by!(user: admin, project: gondor, title: "Light the beacons of Gondor") do |t|
    t.due_date = Date.tomorrow
  end

  # --- Standalone todos (a wizard's errands) ---
  Todo.find_or_create_by!(user: admin, title: "Restock pipeweed supply") do |t|
    t.due_date = Date.current
  end

  Todo.find_or_create_by!(user: admin, title: "Send eagle to check on Frodo") do |t|
    t.due_date = Date.yesterday
  end

  # --- A note on the daily page ---
  page = DailyPage.find_or_create_for(admin, Date.current)
  if page.notes.empty?
    page.notes.create!(user: admin, body: "A wizard is never late, nor is he early. He arrives precisely when he means to.")
  end

  puts "Middle-earth sample data created. One does not simply walk into production."
end
