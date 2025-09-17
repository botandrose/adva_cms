# Repository Guidelines

## Project Structure & Module Organization
- `lib/`: Gem source (engine code under `lib/adva/`, extensions under `lib/rails_ext/`, rake tasks in `lib/tasks/`).
- `app/`: Rails engine components (controllers, models, views, assets) used by host apps.
- `config/`: Engine configuration (`environment.rb`, `routes.rb`).
- `test/`: Test suite (functional and helpers). Files end with `*_test.rb`.
- `vendor/`: Vendored gems/plugins; `pkg/`: built gem artifacts.

## Build, Test, and Development Commands
- Install deps: `bundle install`
- Build gem: `bundle exec rake build` (outputs to `pkg/`).
- Release gem: `bundle exec rake release` (tags and pushes; maintainers only).
- Run a single test file: `bundle exec ruby -Itest test/functional/user_controller_test.rb`
- Run multiple tests (example): `bundle exec ruby -Itest test/functional/page_articles_controller_test.rb`

For manual testing, add this gem to a host Rails app (`Gemfile`: `gem 'adva', path: '../adva'`) and run the app.

## Coding Style & Naming Conventions
- Ruby/Rails style with 2‑space indentation; UTF‑8 source files.
- Classes/Modules: `CamelCase`; methods/variables/files: `snake_case`.
- Filenames mirror constants (e.g., `lib/adva/has_permalink.rb` → `Adva::HasPermalink`).
- Prefer small, focused modules; keep Rails extensions in `lib/rails_ext/`.

## Testing Guidelines
- Framework: Test::Unit with shoulda-style DSL and RR/matchy helpers.
- Place tests under `test/` mirroring code structure; name files `*_test.rb`.
- Add fixtures or contexts alongside related tests where applicable.
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
