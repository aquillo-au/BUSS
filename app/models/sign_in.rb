class SignIn < ApplicationRecord
  belongs_to :person

  scope :active, -> { where(left_at: nil) }
end
