# Dashi

Personal project management app for tracking daily todos, medium-term projects, and long-term goals. Built for a small group of invited users (not public).

## Tech Stack

- **Framework:** Rails 8.1 (Ruby 3.4)
- **Frontend:** Hotwire (Turbo + Stimulus) + Tailwind CSS (custom components, no component library)
- **Database:** SQLite with Litestream for continuous backups to S3/Tigris
- **Auth:** Magic link (passwordless) via Resend, invite-only registration
- **Testing:** RSpec + FactoryBot + Shoulda Matchers + Capybara system tests
- **Deployment:** Fly.io, single machine

## Architecture

### Three-Tier Hierarchy: Goal → Project → Todo

- **Goal** — long-term (months/year), e.g., "Get fit", "Learn Spanish"
- **Project** — medium-term (weeks/months), belongs to a Goal, e.g., "Run 3x/week"
- **Todo** — daily actionable item, optionally belongs to a Project, e.g., "Run 5k today"

Todos can exist standalone (not linked to any Project).

### Daily Page

The primary UI is a daily page showing:
- Todos due today
- Incomplete todos from previous days (carryover, offered for acceptance/dismissal/reschedule)
- Grouped by Project (or ungrouped for standalone todos)

### Sharing Model

- Goals and Projects can be shared between users via a polymorphic `Membership` model
- Shared items can have todos assigned to specific members
- Assigned todos appear on the assignee's daily page

### Key Models

- `User` — email, name, admin flag
- `Invitation` — email, token, invited_by, accepted_at
- `Goal` — title, description, user_id, status, position
- `Project` — title, description, goal_id, user_id, status, position
- `Todo` — title, project_id (optional), user_id, due_date, completed_at, position, notes
- `Membership` — user_id, memberable (polymorphic), role
- `Note` — body, notable (polymorphic)
- `DailyPage` — user_id, date

## Development Commands

```bash
bin/dev              # Start dev server (Rails + Tailwind watcher)
bin/rails server     # Rails server only
bin/rails console    # Rails console
bin/rails db:migrate # Run migrations
bundle exec rspec    # Run all tests
bundle exec rspec spec/models/       # Model specs
bundle exec rspec spec/system/       # System/browser tests
bundle exec rspec spec/requests/     # Request/controller specs
```

## Code Conventions

### General
- Follow standard Rails conventions (RESTful routes, thin controllers, fat models)
- Use `Current` for request-scoped state (current user, etc.)
- Prefer scopes over class methods for queryable logic
- Keep controllers focused — one resource per controller

### Models
- Validate at the model level, not just the database level
- Use `has_many ... dependent:` to specify cascade behavior explicitly
- Position columns use `acts_as_list` or manual integer ordering
- Status fields use Rails enums

### Views
- Tailwind CSS for all styling — no custom CSS files unless absolutely necessary
- Build reusable UI with partials and helpers (no ViewComponent)
- Use Turbo Frames for inline editing and modal-like interactions
- Use Turbo Streams for real-time updates (check-off todos, reorder)
- Stimulus controllers for client-side behavior (drag-and-drop, dropdowns, etc.)

### Testing
- RSpec with FactoryBot for test data
- Model specs for validations, associations, scopes, and business logic
- Request specs for controller actions and authentication
- System specs (Capybara) for critical user flows (daily page, CRUD, auth)
- Use `shoulda-matchers` for concise association/validation specs
- Prefer `let` and `before` blocks over instance variables

### Auth
- Magic links are short-lived (15 minutes) and single-use
- Sessions stored in cookies (Rails default encrypted cookies)
- Admin users can send invitations
- No public registration — must be invited

## Deployment (Fly.io)

### Environment Variables
- `SECRET_KEY_BASE` — Rails secret
- `RESEND_API_KEY` — for sending magic link emails
- `APP_HOST` — production hostname (e.g., `dashi.fly.dev`)
- `LITESTREAM_ACCESS_KEY_ID` — S3/Tigris access key
- `LITESTREAM_SECRET_ACCESS_KEY` — S3/Tigris secret key
- `LITESTREAM_BUCKET` — backup bucket name
- `LITESTREAM_ENDPOINT` — S3-compatible endpoint (e.g., Tigris)

### First Deploy
```bash
fly launch                                           # Create app (skip db, use existing fly.toml)
fly volumes create dashi_storage --region iad --size 1  # 1GB persistent volume
fly secrets set SECRET_KEY_BASE=$(bin/rails secret)
fly secrets set RESEND_API_KEY=re_xxxxx
fly secrets set APP_HOST=dashi.fly.dev
fly secrets set LITESTREAM_ACCESS_KEY_ID=xxxxx
fly secrets set LITESTREAM_SECRET_ACCESS_KEY=xxxxx
fly secrets set LITESTREAM_BUCKET=dashi-backups
fly secrets set LITESTREAM_ENDPOINT=https://fly.storage.tigris.dev
fly deploy
fly ssh console -C "/rails/bin/rails 'users:create_admin EMAIL=you@example.com NAME=YourName'"
```

### Ongoing
```bash
fly deploy           # Deploy to Fly.io
fly ssh console      # SSH into the running machine
fly logs             # Tail logs
```

### How it works
SQLite databases live in `/rails/storage/` on a persistent Fly volume. Litestream continuously replicates the WAL to object storage. On machine restart, `bin/docker-entrypoint` restores from the latest backup before Rails boots. The entrypoint then runs Litestream as a wrapper process that replicates in the background while Rails serves requests.
