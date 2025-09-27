# BelongsToCacheable

`belongs_to_cacheable` provides a simple way to denormalize and cache attributes from a `belongs_to` association into the parent model. This helps to optimize database performance by avoiding N+1 queries and expensive JOINs, allowing you to display associated data without loading the associated record.

## The Problem

Imagine you have a `Post` model that belongs to an `Author`.

```ruby
class Post < ActiveRecord::Base
  belongs_to :author
end

class Author < ActiveRecord::Base
  has_many :posts
end
```

If you want to display a list of posts with their author's name, you might do this in your view:

```erb
<% @posts.each do |post| %>
  <h2><%= post.title %></h2>
  <p>By <%= post.author.name %></p>
<% end %>
```

This will result in an N+1 query. For every post, a separate query is executed to fetch the author's name. You can solve this with `includes(:author)`, but what if you could cache the author's name directly on the `post` record?

## Solution with `belongs_to_cacheable`

`belongs_to_cacheable` allows you to cache attributes from the `author` association on the `posts` table.

### 1. Database Schema

First, add columns to your model's table (`posts` in this case) for each attribute you want to cache, prefixed with the association name.

For example, to cache the `name` of the `author`, add an `author_name` column to the `posts` table:

```ruby
class AddAuthorNameToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :author_name, :string
  end
end
```

### 2. Model Setup

In your model, use `belongs_to_cacheable` instead of the standard `belongs_to`:

```ruby
class Post < ActiveRecord::Base
  belongs_to_cacheable :author
end
```

The gem will automatically identify the `author_name` column and cache the `name` attribute from the `author` record.

### 3. How it Works

- **Caching on Save:** When you save a `Post` record, it automatically copies the value of `author.name` into the `post.author_name` column.

  ```ruby
  author = Author.create!(name: "John Doe")
  post = Post.create!(title: "My first post", author: author)

  post.author_name # => "John Doe"
  ```

- **Automatic Fallback:** The accessor for the cached attribute (`author_name`) is smart. If the cached value is `nil`, it will fall back to the actual association:

  ```ruby
  post.author_name # Reads from the cached `author_name` column
  # If post.author_name is nil...
  post.author.try(:name) # It will call this instead
  ```

- **Association Mocking:** If you access the association itself (`post.author`) and the association hasn't been loaded, it will build a temporary, in-memory `Author` object using the cached attributes. This is useful for display purposes when you don't need the full, persisted record.

  ```ruby
  # If the author association is not loaded (e.g. post = Post.first)
  author = post.author
  author.name # => "John Doe" (from the cached `author_name`)
  author.persisted? # => false
  ```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'belongs_to_cacheable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install belongs_to_cacheable

## Usage

The `belongs_to_cacheable` macro works similarly to `belongs_to`, but with some key differences.

```ruby
belongs_to_cacheable :association_name, [options]
```

By default, the association is treated as **polymorphic**.

### Polymorphic Associations

The gem was designed with polymorphic associations in mind. For example, if a `Comment` can belong to a `Post` or an `Article`:

```ruby
class Comment < ActiveRecord::Base
  # Assumes `commentable_type` and `commentable_id` columns exist
  # Caches `commentable.title` to `commentable_title`
  belongs_to_cacheable :commentable
end
```

### Configuration

- **Validation:** By default, `belongs_to_cacheable` adds `validates_presence_of` and `validates_associated` for the association. You can disable this:

  ```ruby
  belongs_to_cacheable :author, validate: false
  ```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request