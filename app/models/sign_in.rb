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

  def meal_served?
    %w[Cafe Smart\ Lunch Bathurst\ Buddies Frypan\ Warriors].include?(category_label)
  end

  #category mapping by day-of-week (used by reports)
  def category_label
    return "Misc/Unknown" unless arrived_at

    t = arrived_at.in_time_zone # uses config.time_zone
    wday = t.wday
    time = t.strftime("%H:%M")

    case wday
    when 1
      "Frypan Warriors"
    when 2
      if time < "12:30"
        "Working Group"
      elsif time < "15:00"
        "Bible Study"
      elsif time >= "16:00"
        "Board Meetings"
      else
        "Misc/Unknown"
      end
    when 3
      if time < "13:30"
        "Smart Lunch"
      else
        "Activities"
      end
    when 5
      if time < "12:00"
        "Bathurst Buddies"
      else
        "Community Gardens"
      end
    when 6
      if time < "12:30"
        "Music BUSS"
      else
        "Cafe"
      end
    when 0
      "Cafe"
    else
      "Misc/Unknown"
    end
  end
end
