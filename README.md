# BoardPackager Take-Home — Task List

A task list application built with **Ruby on Rails 8.1** running in a **Docker Compose** environment (Rails + PostgreSQL), per the take-home brief. All six required items are implemented, plus all four extra items.

## Quick start

```bash
docker compose build
docker compose up
# first boot runs db:prepare (creates DB + runs migrations) automatically
```

Then open http://localhost:3000.

The app timezone defaults to UTC. To review “due by end of today” in your own timezone, set `APP_TIME_ZONE` on the `web` service, for example `APP_TIME_ZONE="America/New_York"`.

Seed demo data (2 users, 5 tasks covering upcoming / due today / overdue / completed):

```bash
docker compose run --rm web bin/rails db:seed
```

Sign in as **alice@example.com / password** (or bob@example.com / password). Users are created via seeds or the Rails console per the brief — there is no sign-up flow and no admin account.

## Running the tests

```bash
docker compose run --rm web bash -c "RAILS_ENV=test bin/rails db:prepare && bin/rails test"
```

## Feature coverage

| # | Requirement | Where |
|---|-------------|-------|
| 1 | Create a task (title, description, created time, due time) | `feat: create task` + `feat: task validations` |
| 2 | Open a single task | `feat: task detail page` |
| 3 | Mark a task completed | `feat: mark task completed` |
| 4 | Edit title / description / date to complete | `feat: edit task` |
| 5 | Delete a task | `feat: delete task` |
| 6 | List all tasks: sorted by due date asc, overdue marked, “due by end of today” limit | `feat: task list sorted by due date` + `feat: overdue badge` + `feat: due-today filter` |
| E1 | Upload supporting files | `feat: file attachments (extra)` |
| E2 | More filters for the list page | `feat: status filters for list (extra)` |
| E3 | Text search for the list page | `feat: text search (extra)` |
| E4 | User-specific tasks with authentication | `feat: authentication with rails 8 generator (extra)` + `feat: user-scoped tasks (extra)` |

The git history is deliberately incremental — one focused commit per story, tests included in the same commit as the behavior they cover.

## Architecture & key decisions

- **Completion is a timestamp, not a boolean.** `completed_at: datetime` doubles as the flag (`nil` = open) and the audit trail of *when* the task was finished. “Overdue” is derived (`!completed? && due_at.past?`), never stored, so it can’t go stale.
- **“Due by end of today” includes overdue tasks** — they are still due by the end of today. The boundary is `Time.zone.now.end_of_day` with `config.time_zone` set explicitly, so “today” follows the app timezone instead of UTC. It defaults to UTC and is overridable with `APP_TIME_ZONE` (for example `APP_TIME_ZONE="Asia/Singapore"`), so you can see the boundary in your own day rather than in mine.
- **Server-rendered ERB + Hotwire, no SPA.** For an 8-hour budget, Rails’ default stack gives CRUD, forms, validation display and confirmation dialogs with almost no client code.
- **Hard delete** (no soft-delete/paranoia) — the brief asks for delete; recoverability wasn’t requested and would add schema noise.
- **Authentication mirrors the Rails 8 auth generator**: `has_secure_password`, a `sessions` table with one row per sign-in, a signed permanent cookie, and rate-limited sign-in attempts. Password reset was cut deliberately (no mailer in scope).
- **Authorization by scoping, not by checking**: every query goes through `Current.user.tasks`, so another user’s task is indistinguishable from a missing one (404) and nothing leaks. `tasks.user_id` is nullable because rows created before auth existed stay valid; with more time: backfill, then tighten to `null: false`.
- **Filters are whitelisted** in `TasksController::FILTERS`; unknown values fall back to “all”, so params can never call arbitrary scopes.
- **Search** uses `ILIKE` with `sanitize_sql_like` (user-typed `%`/`_` match literally). `ILIKE` is PostgreSQL-specific — acceptable because Postgres is the only target database.
- **Attachments** use Active Storage (disk service) with manual size/type validation (≤10 MB; png/jpeg/pdf/txt) since Active Storage ships no built-in validations. Blobs are purged in the background (`dependent: :purge_later`). Only the attachments added in the current save are validated, so editing a title does not re-read blobs that were already accepted. Active Storage identifies each blob from its bytes with Marcel, so a renamed file with a faked `Content-Type` is rejected. The remaining gap is a file whose bytes carry no recognisable signature, where Marcel falls back to the declared type.
- **Schema is expressed as plain migrations** (including the Active Storage tables) so the whole history is reviewable commit by commit.

## Notes for reviewers

- `Gemfile.lock` and `db/schema.rb` are both checked in and match the migrations, so a fresh `docker compose up` needs no extra steps.

## What I’d do with more time

- Backfill `tasks.user_id` and tighten to `null: false`.
- Pagination on the list page; system tests (Capybara) for the happy paths.
- Trigram index (`pg_trgm`) for search: the current `%term%` pattern cannot use a btree index.
- Re-add the system-test CI job together with the first Capybara test. It was removed because there were no system tests for it to run.
- Direct uploads + antivirus scanning hook for attachments.
- Password reset via mailer.

## Approximate time log (~8h)

| Block | Time |
|-------|------|
| Docker/Rails skeleton & CI setup | 0.5h |
| Items 1–6 (TDD: model → request → views) | 3.5h |
| Auth + user scoping | 1.5h |
| Filters + search | 1.0h |
| File attachments | 1.0h |
| Seeds, polish, README | 0.5h |
