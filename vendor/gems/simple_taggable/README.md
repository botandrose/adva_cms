# Simple Taggable

`simple_taggable` is a Ruby gem that provides an easy way to add tagging functionality to your ActiveRecord models.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_taggable'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install simple_taggable
```

Next, you need to generate and run the migration to create the `tags` and `taggings` tables:

```bash
$ rails generate simple_taggable:migration
$ rake db:migrate
```

## Usage

### Making a Model Taggable

To make a model taggable, you just need to add `acts_as_taggable` to it:

```ruby
class Post < ActiveRecord::Base
  acts_as_taggable
end
```

You also need to add a `cached_tag_list` string column to the model you want to make taggable. You can do this by creating a migration:

```bash
$ rails generate migration AddCachedTagListToPosts cached_tag_list:string
$ rake db:migrate
```

### Adding and a Taggable Model

Once a model is taggable, you can set its tags using the `tag_list` attribute:

```ruby
post = Post.new(:title => "My first post")
post.tag_list = "ruby, rails, web"
post.save
```

You can also add and remove tags using the `tag_list_add` and `tag_list_remove` methods:

```ruby
post.tag_list_add("programming")
post.tag_list_remove("web")
post.save
```

The `tag_list` attribute will be automatically cached in the `cached_tag_list` column of the model.

### Finding Objects by Tag

You can find objects by tag using the `tagged` class method:

```ruby
# Find posts tagged with "ruby"
Post.tagged("ruby")

# Find posts tagged with "ruby" or "rails"
Post.tagged("ruby", "rails")

# Find posts tagged with "ruby" and "rails"
Post.tagged("ruby", "rails", :match_all => true)

# Find posts tagged with "ruby" but not "java"
Post.tagged("ruby", :except => "java")
```

### Tag Counts

You can get the tag counts for a model using the `tag_counts` class method:

```ruby
# Get all tag counts
Post.tag_counts

# Get tag counts for a specific set of tags
Post.tag_counts(:conditions => "tags.name IN ('ruby', 'rails')")
```

## Contributing

1.  Fork it
2.  Create your feature branch (`git checkout -b my-new-feature`)
3.  Commit your changes (`git commit -am 'Add some feature'`)
4.  Push to the branch (`git push origin my-new-feature`)
5.  Create new Pull Request
