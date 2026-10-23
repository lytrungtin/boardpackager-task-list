# BoardPackager

BoardPackager is a task list for board packagers and property managers. It keeps the day-to-day work of a building in one place: what is due, what is late, what is done, and who owns it.

Built with Ruby on Rails 8.1, PostgreSQL, Hotwire, and Active Storage. Runs locally with Docker Compose.

## Features

- Create, edit, complete, reopen, and delete tasks.
- Due dates with an overdue badge and a "due today" view.
- Status filters for active, completed, overdue, and due today.
- Search across task title and description.
- File attachments: PNG, JPEG, PDF, and text files up to 10 MB.
- Per-user task lists with session-based authentication.
- Optimistic locking so two tabs cannot silently overwrite each other.
- Server-rendered ERB and Hotwire. No SPA, no separate API client.

## Stack

- Ruby 3.3.12
- Rails 8.1
- PostgreSQL 16
- Hotwire: Turbo and Stimulus
- Propshaft, import maps
- Active Storage
- Docker Compose for development
- Minitest for tests

## Getting started

```bash
docker compose build
docker compose up
```

The first boot creates the database, runs migrations, and starts the app at http://localhost:3000.

Seed demo data:

```bash
docker compose run --rm web bin/rails db:seed
```

Sign in as `alice@example.com` or `bob@example.com`, password `password`. There is no sign-up flow. Users are created through seeds or the Rails console.

Set the app timezone if you want "today" to follow your local day:

```bash
APP_TIME_ZONE="Asia/Singapore" docker compose up
```

The default is UTC.

## Tests

```bash
docker compose run --rm web bash -c "RAILS_ENV=test DATABASE_URL=postgres://app:***@db:5432/app_test bin/rails db:test:prepare test"
```

The suite covers models, controllers, authentication, user scoping, search escaping, attachments, and optimistic locking.

## How it works

### Tasks

A task has a title, optional description, due date, optional completion time, and optional attachments. Tasks belong to a user.

`completed_at` is a timestamp, not a boolean. `nil` means the task is open, and any value records when it was finished. Overdue is derived at read time (`due_at` in the past and not completed), so it can never go stale.

The "due today" view includes tasks that are already overdue. They are still due by the end of today.

### Authorization

Every task query goes through `Current.user.tasks`. Another user's task is indistinguishable from a missing one, so the app returns 404 instead of leaking whether the task exists.

### Concurrency

Task edits use optimistic locking. The form sends `lock_version`, and a stale save returns 409 with a reload prompt instead of overwriting the first writer.

### Attachments

Active Storage stores files on disk in development. The model validates size and content type, and only newly attached blobs are checked, so editing a title does not re-read files that were already accepted. Blobs are purged in the background when a task is deleted.

### Database

Tasks are indexed by `(user_id, due_at)` for user-scoped due-date queries. Search uses PostgreSQL `ILIKE` with escaped wildcards.

## Configuration

- `APP_TIME_ZONE`: app timezone, default `UTC`.
- `DATABASE_URL`: database connection. Compose points development at `app_development` and tests at `app_test`.
- Production uses `APP_DATABASE_PASSWORD` and disables demo seeds.

## Roadmap

- Pagination for the task list.
- `pg_trgm` index for search.
- Backfill `tasks.user_id` and make it non-null.
- System tests for the main flows.
- Direct uploads and antivirus scanning for attachments.
- Password reset.

## License

MIT. See [LICENSE](LICENSE).
