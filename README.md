# About

Simple ORM. It uses Redis hashes. Supports validations, default values, setting values on create/update and data types (Redis stores every value as a string).

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

      def key
        "users.#{self.username}"
      end
    end
  end
end
```
