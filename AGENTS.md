# Repository Guidelines

## Project Structure & Module Organization
- `lib/`: Gem source (engine code under `lib/adva/`, extensions under `lib/rails_ext/`, rake tasks in `lib/tasks/`).
- `app/`: Rails engine components (controllers, models, views, assets) used by host apps.
- `config/`: Engine configuration (`environment.rb`, `routes.rb`).
- `spec/`: RSpec test suite (requests, models, helpers). Files end with `*_spec.rb`.
- `vendor/`: Vendored gems/plugins; `pkg/`: built gem artifacts.

## Build, Test, and Development Commands
- Install deps: `bundle install`
- Build gem: `bundle exec rake build` (outputs to `pkg/`).
- Release gem: `bundle exec rake release` (tags and pushes; maintainers only).
- Run all tests: `bundle exec rspec`
- Run a single test file: `bundle exec rspec spec/requests/admin_users_crud_spec.rb`
- Run tests matching pattern: `bundle exec rspec spec/requests/`

For manual testing, add this gem to a host Rails app (`Gemfile`: `gem 'adva', path: '../adva'`) and run the app.

## Coding Style & Naming Conventions
- Ruby/Rails style with 2‑space indentation; UTF‑8 source files.
- Classes/Modules: `CamelCase`; methods/variables/files: `snake_case`.
- Filenames mirror constants (e.g., `lib/adva/has_permalink.rb` → `Adva::HasPermalink`).
- Prefer small, focused modules; keep Rails extensions in `lib/rails_ext/`.

## Testing Guidelines
- Framework: RSpec with request specs for controllers, unit specs for models.
- Place tests under `spec/` mirroring code structure; name files `*_spec.rb`.
- Use factories or let blocks for test data setup where applicable.
- Ensure new code is covered; run targeted files locally while iterating.

## Commit & Pull Request Guidelines
- Commits: imperative, concise messages (e.g., "fix activity links on homepage.").
- Version bumps use "release vX.Y.Z."; keep changelog entries minimal and factual.
- PRs must: describe the change, link issues, include repro steps, and add tests.
- UI or asset changes: include before/after screenshots or HTML snippets.
- Keep diffs focused; separate refactors from functional changes when possible.

## Security & Configuration Tips
- Do not commit secrets; configuration belongs in the host app.
- When touching assets or engine wiring, verify routes in `config/routes.rb` and precompilation entries in `lib/adva.rb`.
