class Person < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  has_many :sign_ins, dependent: :destroy

  def present!
    update!(present: true)
  end

  def absent!
    update!(present: false)
  end

end
