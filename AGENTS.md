# Repository Guidelines

## Project Structure & Module Organization
- `app/`: Rails MVC. JavaScript lives in `app/javascript/` (Stimulus controllers), assets under `app/assets/` and compiled builds in `app/assets/builds/`.
- `config/`: Rails, environment, Sidekiq, Tailwind configs. `config.ru` for Rack. `db/` holds migrations and schema.
- `lib/`: reusable utilities. `public/`: static assets. `bin/`: helper executables (`rails`, `dev`, `rubocop`, `brakeman`, `setup`).
- `spec/`: RSpec tests (models, requests, system), `spec/factories/` for FactoryBot. `test/` exists for legacy/system tests.
- `job/`, `storage/`, `tmp/`: background jobs/data, storage, and runtime files.

## Build, Test, and Development Commands
- Setup: `bin/setup` (installs gems, prepares DB). Docker: `docker compose up --build` (brings up Postgres, Redis, web, Sidekiq).
- Run server: `bin/rails s` (http://localhost:3000).
- Assets/watchers: `bin/dev` (runs `yarn build --watch` and `tailwindcss:watch` from `Procfile.dev`). Keep it in a separate terminal.
- Tests: `bundle exec rspec` (uses `.rspec` and `spec/rails_helper.rb`).
- Lint/Security: `bin/rubocop` and `bin/brakeman`.
- JS build: `yarn build` (outputs to `app/assets/builds`).
 - All-in-one check: `bin/check` (runs RuboCop, Brakeman, and RSpec).

## Coding Style & Naming Conventions
- Ruby: 2-space indent, snake_case, follow Rails conventions. RuboCop Rails Omakase enforces style.
- RSpec: name files `*_spec.rb`; group by type (`spec/models`, `spec/requests`, etc.). Use FactoryBot and Faker.
- JavaScript: ES modules in `app/javascript`; Stimulus controllers named `*_controller.js` in `app/javascript/controllers/`.
- i18n & Styles: prefer `t('...')`; use Tailwind/DaisyUI classes in views.

## Testing Guidelines
- Cover models (validations/scopes), requests/controllers, and features where applicable.
- Keep tests deterministic; avoid external calls. Use factories.
- Run `bundle exec rspec` locally and ensure it’s green before opening a PR.

## Commit & Pull Request Guidelines
- Commit format: short, prefixed subjects (e.g., `feat: add gift listing`, `fix: correct Dockerfile`, `style: tweak button color`). History also includes `add:` and `Lint:`.
- Pull Requests: include a clear description, linked issues, screenshots for UI changes, and notes on migrations. Ensure tests pass and linting is clean.

## Security & Configuration
- Configuration via dotenv: local secrets in `.env`. Do not commit secrets; if secrets were committed, rotate them immediately and purge from history.
- Services: PostgreSQL and Redis required. Sidekiq uses `config/sidekiq.yml`.
