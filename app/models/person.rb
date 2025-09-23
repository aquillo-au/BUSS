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
  # Move associations
  SignIn.where(person_id: other.id).update_all(person_id: self.id)
  Note.where(person_id: other.id).update_all(person_id: self.id)
  # Add other associations as needed

  # Optionally merge attributes if desired, e.g. phone/email/history

  # Delete the other person
  other.destroy!
end

end
