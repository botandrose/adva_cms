# CacheableFlash

CacheableFlash is a Rails gem that makes flash messages compatible with page caching. It moves flash messages from the session to the browser's cookies, allowing you to use flash messages on cached pages without them being cached as well.

## Problem

Rails' default flash implementation relies on the session. When you use page caching, the entire page, including the flash message, is stored and served to all subsequent users. This means that if a user performs an action that generates a flash message (e.g., "Post created successfully"), that message will be cached and displayed to everyone who visits that page, which is often not the desired behavior.

## Solution

CacheableFlash solves this problem by storing the flash messages in the user's cookies instead of the session. Here's how it works:

1.  An `around_action` in your controller intercepts the request after it has been processed.
2.  It takes any flash messages that have been set, serializes them to JSON, and writes them to a cookie named `flash`.
3.  The original flash is then cleared.
4.  A middleware injects a small JavaScript snippet into the `<head>` of the HTML response.
5.  On the client-side, this JavaScript reads the `flash` cookie, displays the messages in the appropriate elements on the page, and then deletes the cookie.

This ensures that flash messages are specific to the user who initiated the action and are not cached along with the page.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cacheable_flash'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install cacheable_flash

The gem includes a Rails Engine that automatically includes the necessary middleware and controller modules, so no further setup is required.

## Usage

To display the flash messages, you need to have elements in your views with IDs that correspond to the flash message keys. The supported keys are `notice`, `alert`, and `error`.

For example, in your `application.html.erb` layout file, you could have:

```html
<div id="flash_notice" hidden></div>
<div id="flash_alert" hidden></div>
<div id="flash_error" hidden></div>
```

The JavaScript included by the gem will look for these elements and insert the flash messages into them. The `hidden` attribute will be removed to make the message visible.

## How It Works

### Controller

The `CacheableFlash::Controller` module is included in `ActionController::Base`. It uses an `around_action` called `write_flash_to_cookie` to serialize the flash hash to JSON and store it in the `flash` cookie. It then clears the original flash hash to prevent it from being stored in the session.

### Middleware

The `CacheableFlash::Middleware` is responsible for injecting the JavaScript file (`lib/cacheable_flash/javascript.js`) into the `<head>` of the HTML response. This is done for any request with a `Content-Type` of `text/html`.

### JavaScript

The injected JavaScript runs on `DOMContentLoaded`. It performs the following actions:

1.  Looks for a cookie named `flash`.
2.  If the cookie is found, it parses the JSON content.
3.  It then looks for elements with the IDs `flash_notice`, `flash_alert`, and `flash_error`.
4.  If a matching element is found for a message in the cookie, the message is inserted into the element, and the element is made visible.
5.  Finally, the `flash` cookie is deleted.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/adva/cacheable_flash.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).