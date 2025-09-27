# Adva

Adva is a Rails engine that provides a compact, extensible CMS core you can embed in a host Rails app. It ships with a multi‑site model, hierarchical sections, simple content types, nested categories, tagging, an admin area, authentication helpers, and a small set of Rails extensions and helpers to wire things together.

This README focuses on the functionality you get as a developer: models, controllers, helpers, routes, and extension points.

## At a Glance

- Sites: multi‑site support with per‑site settings and activity log
- Sections: hierarchical navigation (nested set), permalinked paths
- Content: `Article` and `Link` as first‑class content under sections
- Categories: nested categories per section with permalinked paths
- Tagging: `acts_as_taggable` on content; tag filters in public views
- Users: authentication-compatible `User` with memberships per site
- Admin: CRUD for sites, sections, users, articles, links, categories
- Events: lightweight observer bus for domain events (e.g., password)
- Forms: configurable form builder with tabs and callbacks
- Rails Ext: helpers for error rendering, return URLs, and events

## Installation

1) Add the gem to your host app Gemfile:

```ruby
gem 'adva', path: '../adva' # or gem 'adva', '~> 0.3'
```

2) Bundle and copy migrations from the engine, then migrate:

```bash
bundle install
bin/rails railties:install:migrations # copies engine migrations
bin/rails db:migrate
```

3) Assets are automatically added for precompilation by the engine. If your app restricts the precompile list, ensure these are included: `adva_cms.js`, `adva_cms/admin.css`, `admin.js`, `admin.css`, and a handful of icon images under `adva_cms/`.

4) Boot your app and visit `/admin/sites` to administer content. Public content is available at `/` and under section permalinks.

Notes
- The engine does not use `isolate_namespace`, so controllers/routes live in the host app’s space under the `Admin::` namespace for admin, and top‑level for public controllers.
- For single‑site deployments, set `Site.multi_sites_enabled = false` (see Configuration) and use your app’s host to find the site.

## Domain Model

Core models are under `app/models/` and include:

- `Site`: owns `sections`, `users` (via `Membership`), and `activities`.
  - Host and name/title, email, timezone.
  - Multi‑site aware finder: `Site.find_by_host!(host)` respects single‑site mode.
  - Bust cache helper: `Site.bust_cache!` touches all sites.

- `Section` (STI base; default type: `Page`): nested set scoped by site.
  - Permalinks via `Adva::HasPermalink`; full path is built from ancestors.
  - Options via `Adva::HasOptions` (e.g., `contents_per_page`).
  - Associations: `categories`, `contents`, `activities`.
  - Publication helpers: `published?`, `state`, automatic `published_at`.

- `Page < Section`: owns `articles` and `links`; supports `single_article_mode` for “page shows its first article”.

- `Content` (STI base for section content): nested set scoped by section.
  - Acts as taggable; permalinked within section; belongs to `section` and `site`.
  - Author support via `Adva::BelongsToAuthor` (`belongs_to_author`).
  - Scopes: `published`, `drafts`, `by_category(category)`.

- `Article < Content` and `Link < Content`: validations, navigation (`previous`/`next` for articles), and a trivial link content that redirects to its `body` URL in public views.

- `Category`: nested set per section, permalinked paths, `all_contents` fetcher respecting subtree and type.

- `User`: `acts_as_authenticated_user` compatible; validations; `memberships` to sites; `admin` flag; password complexity validation.

- `Membership`: joins users to sites.

- `Activity`: polymorphic activity log with simple “coinciding” grouping and author fields.

## Controllers & Routes

Public
- `ArticlesController#index|show`: renders first/paginated content in a section; filters by `tags` and `category_id`; prevents drafts for non‑admins; redirects `Link` to its URL. Views live under `app/views/pages/articles/`.

Admin
- `Admin::SitesController`: manage sites; respects single‑site mode.
- `Admin::SectionsController`/`Admin::PagesController`: manage sections.
- `Admin::Page::ArticlesController`, `::LinksController`, `::CategoriesController`, `::ContentsController`: manage content for a section.
- `Admin::UsersController`: manage users for a site and admins.
- `SessionController` and `PasswordController`: login/logout, password reset/update.

Routing highlights (see `config/routes.rb`):
- Public page and article routes under `/:section_permalink` and `/:section_permalink/:permalink`.
- Tag and category filters: `/pages/:section_permalink/tags/:tags` and `/.../categories/:category_id`.
- Admin CRUD under `/admin` with nested resources for sections and content.
- Session: `GET /login`, `DELETE /logout`.

## Views & Assets

- Admin layout/templates under `app/views/admin/...` with SCSS and JS in `app/assets` (`admin.scss`, `admin.js`, `adva_cms.js`).
- Public templates for articles under `app/views/pages/articles`.
- The engine adds required assets to `config.assets.precompile` via `Adva::Engine`.

## Helpers & Extensions

Rails Extensions (`lib/rails_ext/`)
- Error procs: `renders_with_error_proc :above_field|:below_field` lets controllers choose error rendering around form fields.
- Return URL support: `url_for(return: :here)` injects `return_to` in links.
- Event helper: `trigger_event(object, change, options={})` and `trigger_events(object, *changes)` call the Adva event bus.

Form Builder (`Adva::ExtensibleFormBuilder`)
- Default form builder is swapped to support:
  - `field_set :name do ... end`
  - `tabs { tab(:settings) { ... }; tab(:seo) { ... } }`
  - `before/after(object_name, method, string_or_block)` callbacks.
  - `buttons { ... }`, default class names, tabindex helpers.

Resource/Content Helpers
- `ResourceHelper`: `resource_url`, `resource_link`, `link_to_index/new/show/edit/delete`, ID/class conventions, and owner‑aware nested URL building.
- `ContentHelper`: tag/category links and status formatting; `link_to_preview`, `content_path` helpers.

## Authentication Mix‑in

`Adva::AuthenticateUser` adds controller‑level helpers and macros:
- `authentication_required` and `no_authentication_required` macros
- `current_user`, `authenticated?`/`logged_in?`
- `authenticate_user(email:, password:)`, `remember_me!`, `logout`
- Token validation helpers for password reset and remember‑me

The engine expects `acts_as_authenticated_user` on `User` (provided by the bundled `authentication` dependency). Admin controllers require an authenticated admin user.

## Event Bus

`Adva::Event.trigger(type, object, source, options={})` notifies observer classes listed in `Adva::Event.observers`.
- The engine registers `PasswordMailer` to handle `user_password_reset_requested` and `user_password_updated`.
- You can add your own observers from the host app (e.g., in an initializer):

```ruby
# config/initializers/adva.rb
Adva::Event.observers << 'MyCustomObserver'

class MyCustomObserver
  def self.handle_event!(event)
    # fan out to your jobs or mailers
  end
end
```

## Configuration

Place host‑app configuration in an initializer, e.g. `config/initializers/adva.rb`:

```ruby
# Single vs multi site mode (default: true)
Site.multi_sites_enabled = true

# Optional: enable verbose cache sweeper logging
Site.cache_sweeper_logging = false

# Add/remove observers
Adva::Event.observers |= %w[PasswordMailer]
```

## Database & Migrations

The engine ships migrations under `db/migrate`. Copy them into your app with `railties:install:migrations` and run `db:migrate`.

Models use serialized columns (YAML) for options/permissions; ensure your DB adapter supports text columns large enough for your data.

## Testing

Run the engine’s specs:

```bash
bundle install
bundle exec rspec
```

From a host app, you can integrate the gem and add request/unit specs against the mounted controllers and models. The repository includes request specs under `spec/requests` that are a good reference starting point.

## Dependencies

- Rails (engine)
- `friendly_id` (slugs + finders)
- `will_paginate` (pagination)
- `awesome_nested_set` (hierarchies for sections/categories/contents)
- `nacelle` and small support gems vendored/required by the engine
- `actionpack-page_caching`, `rails-observers`, `sassc-rails`

See `adva.gemspec` for the authoritative list and versions.

## Development

- Install deps: `bundle install`
- Run tests: `bundle exec rspec`
- Build gem: `bundle exec rake build` (outputs to `pkg/`)

When iterating inside a host app, reference the gem via a local path in the Gemfile and use your app’s server/tests to validate end‑to‑end flows.

## Notes & Limitations

- The engine provides a basic CMS core (sites, sections/pages, articles, links, categories, tagging, admin). Legacy references to forums, wikis, galleries, etc., are not included in this gem.
- Some legacy configuration files under `config/` exist for historical context and are not required for modern Rails setups.

## License

MIT. See `LICENSE`.
