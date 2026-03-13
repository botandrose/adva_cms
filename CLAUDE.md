# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Adva is a **Rails engine** (gem) providing a compact, extensible CMS core. It is not a standalone app — it mounts into a host Rails application. The engine does **not** use `isolate_namespace`, so controllers and routes live in the host app's namespace.

Ruby 3.4.2, tested against Rails 7.2 and 8.0 via Appraisal gemfiles.

## Build & Test Commands

```bash
bundle install                                    # install dependencies
bundle exec rspec                                 # run all engine specs
bundle exec rspec spec/requests/admin_articles_crud_spec.rb  # single file
bundle exec rspec spec/requests/                  # directory
bundle exec rake                                  # default task (runs specs)
bundle exec rake build                            # build gem to pkg/
bundle exec rake spec:gems                        # run specs for all vendored gems
```

For manual testing, add `gem "adva", path: "../adva"` to a host app's Gemfile.

CI matrix: Ruby 3.2/3.3/3.4 x Rails 7.2/8.0, plus independent runs for each vendored gem.

## Architecture

### Domain Model (STI)

- `Section` (base) → `Page` (subclass) — hierarchical navigation via `awesome_nested_set`, scoped by site
- `Content` (base) → `Article`, `Link` (subclasses) — nested set scoped by section
- `Site` owns sections, users (via `Membership`), and activities
- `Category` — nested set per section

### Key Mixins (`lib/adva/`)

- `Adva::HasPermalink` — FriendlyID integration for slugs
- `Adva::HasOptions` — serialized YAML options with typed accessors
- `Adva::BelongsToAuthor` — polymorphic author association
- `Adva::AuthenticateUser` — controller auth macros (`authentication_required`, `current_user`, etc.)
- `Adva::Event` — domain event bus; observers listed in `Adva::Event.observers`
- `Adva::ExtensibleFormBuilder` — custom form builder with tabs, field sets, callbacks
- `Adva::Override` — prepend-based override for host apps to extend controllers/models

### Rails Extensions (`lib/rails_ext/action_controller/`)

- `renders_with_error_proc` — error rendering control (`:above_field`, `:below_field`)
- `url_for(return: :here)` — return URL injection
- `trigger_event` / `trigger_events` — controller helpers for the event bus

### Controllers

- **Public**: `ArticlesController` (index/show with pagination, tag/category filters, Link redirects)
- **Admin**: `Admin::BaseController` plus CRUD controllers for sites, sections, pages, articles, links, categories, users
- **Auth**: `SessionController` (login/logout), `PasswordController` (reset/update)

### Routes

- Public: `/:section_permalink`, `/:section_permalink/:permalink`, tag/category filter variants
- Admin: `/admin/*` with nested resources
- Auth: `/login`, `/logout`, `/session`, `/password`
- Install redirect: `/` → `/admin/install` when no sites exist

### Vendored Gems (`vendor/gems/`)

Six small gems with their own Gemfiles and test suites: `authentication`, `belongs_to_cacheable`, `simple_taggable`, `tags`, `table_builder`, `cacheable_flash`. CI tests each independently.

## Testing Notes

- RSpec with request specs (full-stack) and model specs (unit)
- Test app lives in `spec/internal/` (minimal Rails app for engine testing)
- SQLite for tests
- CSRF disabled, transactional fixtures, event system stubbed in specs
- `SpecAuth` mixin provides `login_as_admin` helper (see `spec/support/auth.rb`)
- Views use Slim templates throughout

## Commit Style

Imperative, lowercase, concise messages (e.g., "fix activity links on homepage."). Version bumps use "release vX.Y.Z."
