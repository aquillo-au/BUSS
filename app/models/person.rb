class Person < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  has_many :sign_ins, dependent: :destroy

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  def present!
    update!(present: true)
  end

  def absent!
    update!(present: false)
  end

  def merge_with!(other)
    SignIn.where(person_id: other.id).update_all(person_id: id)
    other.destroy!
  end
end
