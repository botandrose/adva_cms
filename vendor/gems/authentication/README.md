# Authentication (adva)

Pluggable authentication for ActiveRecord models. This gem provides a small, extensible framework to authenticate a user model via a chain of strategies and to issue and validate login tokens such as “remember me” cookies and single‑use links.

It ships with sensible defaults suitable for many Rails apps:

- Salted password hashing stored on your model
- Persistent “remember me” token
- Expiring single token for password reset/email verification links

You can swap or chain additional strategies (e.g., LDAP) without touching your app code.


## Table of Contents

- Installation
- Quick Start
- Schema Requirements
- How It Works
- Tokens: Assigning and Authenticating
- Customizing Strategies
- Built‑in Strategies
- Providing Your Own Strategy
- Configuration
- ActiveRecord Utilities
- Testing and Development
- License


## Installation

Add to your application Gemfile:

```ruby
gem 'authentication'
```

Then bundle:

```sh
bundle install
```

If you’re developing inside the adva repository, this gem may be vendored; add it to your host app via a path reference:

```ruby
gem 'authentication', path: 'vendor/gems/authentication'
```


## Quick Start

1) Add required columns (see Schema Requirements). For the default strategy set you’ll typically need:

- `password_hash`, `password_salt` (40 chars each)
- `remember_me` (40 chars)
- `token_key` (40 chars), `token_expiration` (datetime)

2) Enable on your model:

```ruby
class User < ActiveRecord::Base
  acts_as_authenticated_user
end
```

3) Set a password and authenticate:

```ruby
user = User.new(name: 'Alice')
user.password = 'secret123'  # will be hashed before validation/save
user.save!

user.authenticate('secret123') #=> true
user.authenticate('wrong')     #=> false
```

4) Issue a token and use it to authenticate:

```ruby
# Expiring single token (e.g., password reset)
key = user.assign_token('password_reset', 2.hours.from_now)
user.save!

user.authenticate(key) #=> true (until expiration)

# Persistent remember-me token
remember_key = user.assign_token('remember me')
user.save!

user.authenticate(remember_key) #=> true (ignores expiration)
```


## Schema Requirements

The default strategy set uses three built‑in strategies. Add columns as needed for the ones you enable:

- Salted password hashing (Authentication::SaltedHash)
  - `password_hash :string, limit: 40`
  - `password_salt :string, limit: 40`
  - Optional: `verified_at :datetime` — when present, password auth requires verification.

- Single expiring token (Authentication::SingleToken)
  - `token_key :string, limit: 40`
  - `token_expiration :datetime`

- Remember‑me token (Authentication::RememberMe)
  - `remember_me :string, limit: 40`

Example Rails migration:

```ruby
change_table :users do |t|
  t.string   :password_hash, limit: 40
  t.string   :password_salt, limit: 40
  t.string   :token_key,     limit: 40
  t.datetime :token_expiration
  t.string   :remember_me,   limit: 40
  # t.datetime :verified_at   # optional
end
```


## How It Works

- `acts_as_authenticated_user` wires your model to a configurable chain of strategies:
  - Password strategies (authenticate with user‑input string, may support `assign_password`).
  - Token strategies (authenticate with a token, may support `assign_token`).
- `user.authenticate(value)` tries token strategies first, then password strategies, returning true on the first success.
- `user.password = '...'` stores a transient plaintext password; before validation the gem passes it to all password strategies that implement `assign_password` so they can hash/persist state.
- Strategies are instantiated once per class and stored on class attributes `authentication_modules` and `token_modules`.

Default strategy set:

```ruby
Authentication.default_scheme = {
  authenticate_with: 'Authentication::SaltedHash',
  token_with: [
    'Authentication::RememberMe',
    'Authentication::SingleToken'
  ]
}
```


## Tokens: Assigning and Authenticating

- `user.assign_token(name, expire = 3.days.from_now)` asks each token strategy to generate a token; it returns the first non‑nil token string and assigns the associated hashed value on the model. Persist with `save!`.
- `user.assign_token!(...)` assigns and immediately saves the record, returning the token.
- Token strings you receive are 40‑character SHA‑1 hex digests of a random string plus a site salt; only the hashed value is stored on the model.
- Token `name` is strategy‑specific. For remember‑me, use a name matching `/remember.?me/i`.

Authentication path:

```ruby
user.authenticate(token_or_password) #=> true/false
```


## Customizing Strategies

You can change strategies per model:

```ruby
class User < ActiveRecord::Base
  # Single password strategy
  acts_as_authenticated_user authenticate_with: 'Authentication::SaltedHash'

  # Token strategies can be one or many
  # acts_as_authenticated_user token_with: ['Custom::JWT', 'Authentication::SingleToken']
end
```

Pass constructor arguments:

```ruby
class User < ActiveRecord::Base
  acts_as_authenticated_user authenticate_with: {
    'Authentication::Ldap' => {
      host: 'ldap.example.org', base: 'dc=example,dc=org',
      bind_dn: 'cn=reader,dc=example,dc=org', bind_password: ENV['LDAP_READER_PW'],
      uid_attribute: 'uid', uid_column: 'name'
    }
  }
end
```

Chain multiple with arguments:

```ruby
acts_as_authenticated_user authenticate_with: [
  { 'Authentication::Ldap' => { host: 'ldap1', base: 'dc=corp,dc=net' } },
  { 'Authentication::Ldap' => { host: 'ldap2', base: 'dc=corp,dc=net' } }
]
```

You can also change the global default (e.g., in an initializer):

```ruby
Authentication.default_scheme = {
  authenticate_with: 'Authentication::Ldap',
  token_with: []
}
```


## Built‑in Strategies

- Authentication::SaltedHash
  - Purpose: hash and verify passwords using a site‑wide salt + per‑user salt.
  - Fields: `password_hash` (40), `password_salt` (40).
  - Behavior: authenticates on exact hash match; if model responds to `verified_at`, requires it to be present.
  - Supports: `assign_password(user, plaintext)`.

- Authentication::SingleToken
  - Purpose: issue and validate a single token with optional expiration; ideal for password reset or verify‑email links.
  - Fields: `token_key` (40), `token_expiration` (datetime).
  - Behavior: authenticates only if token matches and is not expired; `token_expiration` may be `NULL` for non‑expiring tokens.
  - Supports: `assign_token(user, name, expire)`.

- Authentication::RememberMe
  - Purpose: persistent login token suitable for cookies.
  - Field: `remember_me` (40).
  - Behavior: ignores expiration; only assigns when `name` matches `/remember.?me/i`.
  - Supports: `assign_token(user, name, expire=nil)`.

- Authentication::Ldap
  - Purpose: authenticate against an LDAP/ActiveDirectory server.
  - Gem dependency: `ldap`.
  - Options (with defaults):
    - `host: '127.0.0.1'`, `port: LDAP::LDAP_PORT`, `base: 'dc=example,dc=com'`
    - `bind_dn: nil`, `bind_password: nil` (optional reader bind)
    - `uid_attribute: 'uid'` (use `sAMAccountName` for AD)
    - `uid_column: 'name'` (model attribute used as UID)
  - Behavior: binds (optionally) with reader, finds DN by `uid_attribute=uid`, then simple‑binds as user to verify credentials.

- Authentication::Bogus
  - Purpose: development‑only helper that authenticates any password.


## Providing Your Own Strategy

A strategy is a PORO instantiated with `new` that implements one or more of the following instance methods:

- `authenticate(user, credential) => true/false`
  - Required for both password and token strategies; `credential` is either a plaintext password or a token string.
- `assign_password(user, plaintext)`
  - Optional for password strategies; set fields on `user` so future `authenticate` calls succeed.
- `assign_token(user, name, expire) => token_string or nil`
  - Optional for token strategies; return a token string if you’re able to create one and set fields on `user` accordingly. Return `nil` to let the next strategy try.

Use `Authentication::HashHelper` for consistent hashing and access to a site salt:

```ruby
class MyToken
  include Authentication::HashHelper
  def assign_token(user, name, expire)
    token = hash_string("#{name}-#{Time.zone.now}")
    user.my_token = hash_string(token)
    token
  end
  def authenticate(user, token)
    user.my_token == hash_string(token)
  end
end
```


## Configuration

- Site salt: by default the gem derives a salt from `Rails.root`. For stable and secure hashing across deploys, set a constant in an initializer:

```ruby
# config/initializers/authentication.rb
AUTHENTICATION_SALT = ENV.fetch('AUTHENTICATION_SALT')
```

- Timezone: the gem uses `Time.zone` for token expiration; ensure your Rails app sets it appropriately.

- Security note: this gem uses SHA‑1 with salting for password hashing for historical compatibility. For new systems, consider a stronger password strategy (e.g., bcrypt/argon2) behind a custom strategy that implements the same interface.


## ActiveRecord Utilities

- `ActiveRecord::Base.includes_all_columns?(*columns) => true/false`
  - Convenience to check whether a model’s table has all specified columns. Built‑in strategies use this to enable/disable themselves based on your schema.


## Testing and Development

- Run the test suite:

```sh
bundle exec rspec
```

- The specs use SQLite and build a minimal schema at runtime. See `spec/spec_helper.rb` for details and examples of usage patterns.

- Building the gem (from the gem root):

```sh
bundle exec rake build
```


## License

MIT. See `MIT-LICENSE`.

