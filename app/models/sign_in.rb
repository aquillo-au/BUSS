class SignIn < ApplicationRecord
  belongs_to :person

  scope :active, -> { where(left_at: nil) }

  # Calculation cap (2 hours)
  CAP_MINUTES_DEFAULT = 120
  # Auto-logout threshold (3 hours)
  MAX_SESSION_MINUTES = 180

  # End time is when they left, or now for active sign-ins
  def end_time
    left_at || Time.current
  end

  # Raw duration in minutes (rounded)
  def duration_in_minutes
    return 0 unless arrived_at
    ((end_time - arrived_at) / 60.0).round
  end

  # Duration capped at cap_minutes (default 120) for any calculations
  def capped_duration_in_minutes(cap_minutes = CAP_MINUTES_DEFAULT)
    [duration_in_minutes, cap_minutes].min
  end

  # Automatically log out any active sign-ins older than 3 hours.
  # Sets left_at to arrived_at + 3.hours (so the session is capped at 3 hours),
  # and marks the person not present if they have no other active sign-ins.
  def self.auto_logout_overdue!(now = Time.current)
    cutoff = now - MAX_SESSION_MINUTES.minutes

    where(left_at: nil).where("arrived_at <= ?", cutoff).find_each do |s|
      capped_left_at = s.arrived_at + MAX_SESSION_MINUTES.minutes
      # Update sign-in end time
      s.update_columns(left_at: capped_left_at, updated_at: Time.current)

      # If the person has no other active sign-ins, mark them not present
      unless SignIn.exists?(person_id: s.person_id, left_at: nil)
        Person.where(id: s.person_id).update_all(present: false, updated_at: Time.current)
      end
    end
  end

  # Optional: category mapping by day-of-week (used by reports)
  def category_label
    return nil unless arrived_at
    case arrived_at.wday
    when 1 then "Frypan Warriors"   # Monday
    when 3 then "Smart Lunch"       # Wednesday
    when 5 then "Bathurst Buddies"  # Friday
    when 6, 0 then "Cafe"           # Saturday, Sunday
    else
      nil                           # Exclude Tuesday/Thursday
    end
  end
end
