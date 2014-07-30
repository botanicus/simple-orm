# About

Simple ORM. It uses Redis hashes. Supports validations, default values, setting values on create/update and data types (Redis stores every value as a string).

## Limitations

### Lists & Sets

Currently only hashes are supported. If you need an array, just use serialise/deserialise hooks and save it as JSON.

Why? Atomicity, keepin' it simple and not having to chase data all around redis. One key rules 'em all.

### Every Operation Is Attribute-Bound

So for instance you don't have `User#on_update`, but rather `User#updated_at#on_update`.

Why? It's easier and I'm a lazy motherfucker.

```ruby
require 'simple-orm'

class PPT
  module Presenters
    class User < SipmpleORM::Presenter
      attribute(:service).required
      attribute(:username).required
      attribute(:name).required
      attribute(:email).required
      attribute(:accounting_email).default { self.email }
      attribute(:auth_key).private.default { SecureRandom.hex }

      attribute(:created_at).
        deserialise { |data| Time.at(data.to_i) }.
        on_create { Time.now.utc.to_i }

      attribute(:updated_at).
        deserialise { |data| Time.at(data.to_i) }.
        on_update { Time.now.utc.to_i }

      attribute(:extra).
        deserialise { |data| JSON.parse(data) }.
          serialise { |value| value.to_json }
    end
  end


  module DB
    class User < SimpleORM::DB
      presenter PPT::Presenters::User
      key 'users.{username}'
    end
  end
end
```
