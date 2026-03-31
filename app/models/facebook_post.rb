class FacebookPost < ApplicationRecord
  validates :facebook_post_id, uniqueness: true

  scope :recent, -> { order(published_at: :desc) }
end
