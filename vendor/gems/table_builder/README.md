# TableBuilder

Turns Ruby collections into semantic HTML tables using a tiny, expressive DSL. It works in plain Ruby (ERB) and integrates nicely with Rails views.

TableBuilder provides:

- A simple `table_for` helper to render a table for a collection.
- Automatic `<thead>`, `<tbody>`, and `<tfoot>` generation.
- Auto column discovery from record attributes or explicit column definitions.
- A compact block DSL for rows and cells.
- Per-cell/per-row HTML attributes, column class inheritance, and alternating row classes.
- Optional I18n support for header labels.


## Basic Usage

The primary entrypoint is the `table_for` helper exposed by including the `TableBuilder` module. In Rails, include it in a helper (e.g., `ApplicationHelper`) so it’s available in views.

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  include TableBuilder
end
```

Render a table in ERB:

```erb
<% table_for @articles do |table| %>
  <% table.column :id, :title %>

  <% table.row do |row, article| %>
    <% row.cell article.id, article.title %>
  <% end %>
<% end %>
```

This produces a structure like:

```html
<table id="articles" class="articles list">
  <thead>
    <tr>
      <th scope="col">ID</th>
      <th scope="col">Title</th>
    </tr>
  </thead>
  <tbody>
    <tr id="article_1">
      <td>1</td>
      <td>First</td>
    </tr>
    <tr id="article_2" class="alternate">
      <td>2</td>
      <td>Second</td>
    </tr>
  </tbody>
  <!-- optional <tfoot> ... -->
  <!-- more rows ... -->
  <!-- alternating rows get class="alternate" -->
```


## Auto Body and Auto Columns

TableBuilder can generate body rows or even columns for you.

- Auto body: If you define columns but no body rows, the body will be built by calling each column’s attribute on each record.

  ```erb
  <% table_for @articles do |table| %>
    <% table.column :id, :title %>
  <% end %>
  ```

- Auto columns: If you define no columns, TableBuilder looks for `record.attribute_names` on the first record, titleizes them for headers, and renders the corresponding values.

  ```erb
  <%# ActiveRecord models expose attribute_names %>
  <% table_for @articles %>
  ```


## Headers and Footers

The builder automatically creates a header row for your columns. You can also prepend custom header rows and add footers.

```erb
<% table_for @articles do |table| %>
  <% table.column :id, :title %>
  <% table.column 'Action', class: 'action' %>

  <%# extra header row (before the column headers) %>
  <% table.head.row do |row| %>
    <% row.cell "total: #{row.table.collection.size}", colspan: :all, class: 'total' %>
  <% end %>

  <% table.row { |row, a| row.cell a.id, a.title; row.cell 'Edit' } %>

  <% table.foot.row { |row| row.cell 'Footer text' } %>
<% end %>
```

Notes:
- Header cells render as `<th scope="col">` and body/footer cells as `<td>`.
- Use `colspan: :all` to span the full column count.


## Empty Collections

Provide a fallback when the collection is empty using `table.empty`.

```erb
<% table_for [] do |table| %>
  <% table.column :id, :title %>
  <% table.empty :p, 'No records', class: 'empty' %>
<% end %>
```

You can also pass a block to lazily compute the content:

```erb
<% table.empty(:p, class: 'empty') { 'No records' } %>
```


## API Overview

- `table_for(collection, html_options = {}) { |t| ... }`
  - Renders a `<table>` for `collection` and yields a `Table` instance.
  - If called in an environment with `concat` (e.g., Rails views), it streams output; otherwise it returns the HTML string.
  - Default table attributes: `id: collection_name`, `class: "#{collection_name} list"`. Override via `html_options`.

- `Table#column(*names, **options)`
  - Define one or more columns. `name` may be a Symbol or String.
  - Header content: Symbols are translated (see I18n below); Strings render directly.
  - CSS class: Defaults to the provided `name` (as-is), can be overridden via `class:`.
  - Column `class` is inherited by body cells in that column.

- `Table#row(options = {}) { |row, record| ... }`
  - Adds a row per record in the collection and yields the `Row` and the current `record`.
  - By default, odd-indexed rows get `class="alternate"`.
  - For ActiveRecord-like records that respond to `new_record?`, each row gets an `id` based on the record (`dom_id`-style): e.g., `article_1` or `new_article`.

- `Row#cell(*contents, **options)`
  - Adds one `<td>`/`<th>` per content; all cells receive the provided `options`.
  - Use `colspan: :all` to span across all defined columns.

- `Table#head`, `Table#body`, `Table#foot`
  - Access the `<thead>`, `<tbody>`, and `<tfoot>` sections respectively. Each section responds to `row(options) { |row| ... }`.

- `Table#empty(tag_name, content, **options)`
  - Render this tag instead of a table when the collection is empty.


## I18n for Column Headers

When a column name is a Symbol, TableBuilder translates it using the scope:

```
[ TableBuilder.options[:i18n_scope], collection_name, :columns ]
```

For example, with `TableBuilder.options[:i18n_scope] = :app` and records of type `TableBuilderRecord` (collection name `table_builder_records`), the lookup path for `:title` is:

```yaml
en:
  app:
    table_builder_records:
      columns:
        title: Title
```

By default, this gem sets `TableBuilder.options[:i18n_scope] = :adva`. You can change it at initialization time (e.g., in a Rails initializer):

```ruby
# config/initializers/table_builder.rb
TableBuilder.options[:i18n_scope] = :my_app
```


## HTML and CSS Hooks

- Table element: `id` and `class` default to the collection name, e.g., `<table id="articles" class="articles list">`.
- Column CSS class: Each column gets a class (defaults to its name). Body cells in that column inherit this class.
- Alternating rows: Every other body row receives `class="alternate"`.


## Using Without Rails

You can include `TableBuilder` in any Ruby object that responds to `concat` (streaming) or simply use the return value of `table_for`:

```ruby
class Presenter
  include TableBuilder
end

presenter = Presenter.new
html = presenter.table_for([OpenStruct.new(id: 1, title: 'Hello')]) do |t|
  t.column :id, :title
end
# => "<table ...>...</table>"
```


## Options and Extensibility Notes

- `TableBuilder.options[:i18n_scope]`: Sets I18n namespace for header translations.
- The builder uses its own `content_tag` helper and escapes HTML attributes; cell/header contents are marked `html_safe` if they respond to it.
- `collection_name` is derived from the first record’s class name (tableized), or can be overridden by passing `collection_name:` in the options to `Table.new` (advanced use).


## Development

Run the test suite:

```sh
bundle install
bundle exec rspec
```


## License

MIT License. See LICENSE for details.
