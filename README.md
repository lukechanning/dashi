# Dashi

A personal project management app for tracking daily todos, medium-term projects, and long-term goals. Built for a small group of invited users.

## What is Dashi?

Dashi organizes your work into three tiers:

- **Goals** — long-term ambitions that take months or a year (e.g., "Get fit", "Learn Spanish")
- **Projects** — medium-term efforts that support a goal (e.g., "Run 3x/week", "Complete Duolingo Unit 5")
- **Todos** — daily actionable items, optionally linked to a project (e.g., "Run 5k", "Duolingo lesson")

Your daily page shows today's todos and carries over incomplete items from previous days, so nothing falls through the cracks.

Goals and projects can be shared with other users, with todos assignable to specific people.

## Tech Stack

- Ruby on Rails 8 (Ruby 3.3+)
- Hotwire (Turbo + Stimulus) for interactive UI
- Tailwind CSS for styling
- SQLite + Litestream for database with continuous backups
- RSpec for testing
- Deployed on Fly.io

## Development

```bash
bin/setup            # Install dependencies and set up database
bin/dev              # Start dev server
bundle exec rspec    # Run tests
```

### Logging in locally

The app uses magic link auth, so there's no password. To sign in as the seed user in development:

```bash
bin/rails console
```

```ruby
user = User.find_by(email: "admin@example.com")
token = user.generate_magic_token!
puts "http://localhost:3000/auth/verify?token=#{token}"
```

Paste the printed URL into your browser and you're in.

## Deployment

Dashi runs on a single Fly.io machine with SQLite. Litestream continuously backs up the database to S3-compatible object storage.

```bash
fly deploy
```
