namespace :signins do
  desc "Cap sign-ins to 3 hours and close overdue active sessions (idempotent)"
  task cap_to_3h: :environment do
    limit_minutes = 180
    limit = limit_minutes.minutes
    now = Time.current

    clamped_count = 0
    SignIn.where.not(left_at: nil).where.not(arrived_at: nil).find_in_batches(batch_size: 1000) do |batch|
      batch.each do |s|
        next unless s.left_at && s.arrived_at
        if (s.left_at - s.arrived_at) > limit
          s.update_columns(left_at: s.arrived_at + limit, updated_at: now)
          clamped_count += 1
        end
      end
    end
    puts "Clamped #{clamped_count} ended sign-ins to #{limit_minutes} minutes."

    overdue_active = SignIn.where(left_at: nil).where.not(arrived_at: nil).where("arrived_at < ?", now - limit)
    affected_person_ids = overdue_active.distinct.pluck(:person_id)
    closed_active_count = 0

    overdue_active.find_each do |s|
      s.update_columns(left_at: s.arrived_at + limit, updated_at: now)
      closed_active_count += 1
    end
    puts "Closed #{closed_active_count} active sign-ins over #{limit_minutes} minutes."

    if affected_person_ids.any?
      to_clear_ids = affected_person_ids - SignIn.where(person_id: affected_person_ids, left_at: nil).distinct.pluck(:person_id)
      if to_clear_ids.any? && Person.column_names.include?("present")
        Person.where(id: to_clear_ids).update_all(present: false, updated_at: now)
        puts "Marked #{to_clear_ids.size} people as not present."
      else
        puts "No person present flags needed updating or 'present' column missing."
      end
    end

    puts "Done."
  end
end
