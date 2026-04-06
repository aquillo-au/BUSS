class User < ApplicationRecord
  has_secure_password

  enum :role, { basic: 0, admin: 1 }

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :role, presence: true
end
