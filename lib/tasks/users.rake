namespace :users do
  desc "Create an admin user: rake users:create_admin EMAIL=you@example.com NAME='Your Name'"
  task create_admin: :environment do
    email = ENV.fetch("EMAIL") { abort "Usage: rake users:create_admin EMAIL=you@example.com NAME='Your Name'" }
    name = ENV.fetch("NAME", "Admin")

    user = User.find_or_initialize_by(email: email)
    user.name = name
    user.admin = true
    user.save!

    puts "Admin user created: #{user.email} (id: #{user.id})"
  end
end
