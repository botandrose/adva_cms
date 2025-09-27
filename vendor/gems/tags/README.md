# Tags

HTML tag rendering primitives with a lightweight, declarative menu/breadcrumb DSL.

This gem gives you:

- A tiny API to render safe HTML tags from Ruby objects (`Tags::Tag` and friends).
- A composable tree model (`Tags::Node`) to build nested structures.
- A menu system (`Menu::*`) with a builder DSL for defining menus, items, activation, and breadcrumbs.
- A simple `Breadcrumbs` helper that renders a `<ul id="breadcrumbs">` from menu items.

It is designed to be used inside Rails (so you already have ActionView), but can also work in plain Ruby as long as ActionView’s tag helper is available.

## Installation

Add to your Gemfile:

```ruby
gem 'tags'
```

Then bundle:

```bash
bundle install
```

Outside Rails, ensure ActionView’s tag helper is loaded before requiring this gem:

```ruby
require 'action_view/helpers/tag_helper'
require 'tags'
```

## Core Concepts

### Tags: Render HTML safely

- `Tags::Tag`: Base class for all tags. It uses `ActionView::Helpers::TagHelper#content_tag` under the hood.
- Subclasses: `Tags::A`, `Tags::Span`, `Tags::Div`, `Tags::Ul`, `Tags::Li` (and you can subclass to add more).
- Initialization: `Tags::Tag.new(content = nil, **html_attributes)`.
  - Symbol content is titleized automatically (e.g., `:hello_world` → `"Hello World"`).
  - `render` returns an HTML string; pass attributes via `options` or to `render` to merge/override.

Examples:

```ruby
Tags::Span.new(:hello_world).render
# => '<span>Hello World</span>'

Tags::A.new('Home', href: '/').render
# => '<a href="/">Home</a>'

Tags::Ul.new.render do |html|
  html << Tags::Li.new('One').render
  html << Tags::Li.new('Two', class: 'active').render
end
# => "<ul>\n<li>One</li><li class=\"active\">Two</li>\n</ul>"
```

### Trees: Compose nested nodes

- `Tags::Node` provides tree behavior and is the base for menus and tags:
  - `children` is a `Tags::TagsList` that auto-sets `parent` when you append/insert nodes.
  - `parent`, `root`, `parents`, `self_and_parents`, `level` help navigate the tree.
  - `add_class(class_name)` safely accumulates/uniquifies CSS classes on the node’s `options`.

You usually won’t instantiate `Node` directly; it powers `Tags::Tag` and the `Menu` classes.

## Menus DSL

The `Menu` module builds structured navigation with activation and breadcrumbs.

Key classes:

- `Menu::Base`: Common behavior; holds `key`, `url`, `children`, and `active` state.
- `Menu::Item`: A leaf that renders an `<li>` containing a `<span>` or `<a>` depending on whether `url` is set.
- `Menu::Menu`: A `<ul>` wrapper for items.
- `Menu::Group`: A `<div>`-like wrapper that can contain menus and items.
- `Menu::Builder`: The DSL executor used by `define` and `build`.

### Define menus declaratively

Define a menu class and describe its structure once. Build it per request (optionally with a scope) to get activation and helper access.

```ruby
class TopMenu < Menu::Group
  define id: 'top', class: 'top' do |m|
    breadcrumb :site, content: '<a href="/">Site</a>'

    m.menu :left, class: 'left' do |left|
      left.item :sections, url: '/sections'
    end

    m.menu :right, class: 'right' do |right|
      right.item :settings, url: '/settings'
    end
  end
end

top = TopMenu.new.build
top_html = top.render
```

Access nodes by key using array syntax (supports multiple keys and dot-notation):

```ruby
top[:left]                    # immediate child
top[:left, :sections]         # nested
top[:'left.sections']         # dot-notation
top.find(:sections)           # depth-first find
```

### Activation and breadcrumbs

Activate a menu tree with the current request path. The active node is set on the chain from the matching `Menu::Item` up to the root, and `#breadcrumbs` returns the breadcrumb trail as `Menu::Item` objects.

```ruby
top.activate('/sections')
active = top.active           # the deepest active node

# Render breadcrumbs as a <ul id="breadcrumbs">…</ul>
Breadcrumbs.new(active.breadcrumbs).render
```

Activation normalizes the path by stripping query strings and trailing `/pages/...` segments to make matching robust.

### Building with a scope (Rails integration)

Pass a view context (or any object providing URL helpers) to `build(scope)` to enable DSL features that compute URLs and delegate helper calls:

- `item :show, action: :show, resource: :post`
  - Calls `scope.resource_url(action, resource, namespace:, only_path: true)` to compute the URL.
  - Sets the item’s `id` to `:"#{action}_#{type}"`, where `type` comes from `scope.normalize_resource_type(action, type, resource)`.
- `item :custom, url: { controller: 'x', action: 'y' }` delegates to `scope.url_for`.
- Missing methods in the builder delegate to the `scope` when available (so you can call your app helpers inside the DSL).

Example:

```ruby
class AdminMenu < Menu::Group
  define do |m|
    m.namespace :admin
    m.menu :main do |main|
      main.item :dashboard, url: '/admin'
      main.item :show, action: :show, resource: :post
    end
  end
end

# In a Rails view or helper where `self` has `url_for`, etc.
menu = AdminMenu.new.build(self)
menu.activate(request.path)
menu.render
```

### Sections menu (dynamic sections)

`Menu::SectionsMenu` is a specialized item that renders an additional `ul#sections_menu` showing sections returned by a `:populate` proc evaluated on the given scope. It marks the current section as active and decorates each section with a `level_N` class for indentation styling.

```ruby
class Sections < Menu::SectionsMenu
  define do |m|
    # Populate expects a proc on the scope that enumerates sections
    m.options populate: proc { @sections } # e.g., an instance var in your view context
  end
end

# During build, Sections#populate(scope) will convert returned objects
# into menu nodes with proper URLs via `scope.url_for`.
```

## API Overview

- `Tags::Tag`
  - `.tag_name` (class): inferred from class name by default; override in subclasses.
  - `#initialize(content = nil, **options)`
  - `#render(**merge_options) { |html| … }`
  - Protected helpers: `#lf(str)`, `#indent(str)`, `#add_class(name)`

- `Menu::Base`
  - Class: `define(**options, &block)` stores a menu definition (used by `#build`).
  - Instance: `#build(scope = nil)`, `#build?`, `#populate(scope)`, `#activate(path)`, `#activation_path`, `#reset`,
    `#breadcrumbs`, `#namespace`, `#find(key)`, `#[](*keys)`

- `Menu::Builder` (DSL methods available inside `define`/`build`)
  - `id(key)`, `options(hash)`, `parent(node)`, `namespace(ns)`, `activates(node)`,
    `menu(key, type: Menu::Menu, **options, &block)`, `item(key, **options)`, `breadcrumb(key, **options)`

- `Menu::Item`
  - Renders `<li><span>…</span></li>` or `<li><a href=…>…</a></li>` depending on `url`.

- `Breadcrumbs`
  - `Breadcrumbs.new(items).render` → `<ul id="breadcrumbs">…</ul>`; marks the last item with `class="last"`.

## Rails Usage Tips

- Build menus with `build(self)` from a view/helper so the DSL can call `url_for`, `resource_url`, etc.
- Call `menu.activate(request.path)` to set active items before rendering.
- Use `Breadcrumbs.new(menu.active.breadcrumbs).render` in layouts or partials.

## Development

Run the specs:

```bash
bundle exec rspec
```

Run a single file or directory:

```bash
bundle exec rspec spec/menu_spec.rb
bundle exec rspec spec/
```

## License

MIT. See `LICENSE`.
