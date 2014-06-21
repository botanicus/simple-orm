# About

Simple ORM. It uses Redis hashes. Supports validations, default values, setting values on create/update and data types (Redis stores every value as a string).

```ruby
require 'simple-orm'

class PPT
  module Presenters
    class User < Entity
      attribute(:service).required
      attribute(:username).required
      attribute(:name).required
      attribute(:email).required
      attribute(:accounting_email).default { self.email }
      attribute(:auth_key).private.default { SecureRandom.hex }

      attribute(:created_at).
        convert { |data| Time.at(data) }.
        on_create { Time.now.utc.to_i }

      attribute(:updated_at).
        convert { |data| Time.at(data) }.
        on_update { Time.now.utc.to_i }
    end
  end


  module DB
    class User < Entity
      presenter PPT::Presenters::User

      def key
        "users.#{self.username}"
      end
    end
  end
end
```
