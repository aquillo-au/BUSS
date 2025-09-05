class ReportsController < ApplicationController
  # GET /reports/category_averages
  # Optional params:
  # - date: YYYY-MM-DD (shows only that date). If absent, shows last 14 days.
  def category_averages
    @date = parse_date(params[:date])

    range =
      if @date
        @date.beginning_of_day..@date.end_of_day
      else
        14.days.ago.beginning_of_day..Time.current.end_of_day
      end

    sign_ins = SignIn.includes(:person).where(arrived_at: range)
    sign_ins = sign_ins.select { |s| s.category_label.present? }

    # date => category => person => [capped_durations...]
    @by_date_category_person = {}
    sign_ins.each do |s|
      date_key = s.arrived_at.to_date
      category = s.category_label
      next unless category

      @by_date_category_person[date_key] ||= {}
      @by_date_category_person[date_key][category] ||= Hash.new { |h, k| h[k] = [] }
      # Use capped duration for all calculations
      @by_date_category_person[date_key][category][s.person] << s.capped_duration_in_minutes
    end

    # date => [{ person:, average:, visits: }, ...]
    @by_date_person_summary = {}
    # date => { avg_per_person: Integer, people_count: Integer }
    @by_date_collective_average = {}

    @by_date_category_person.each do |date_key, categories|
      # Merge capped durations across categories per person for the date
      person_map = Hash.new { |h, k| h[k] = [] }
      categories.values.each do |people_map|
        people_map.each do |person, durations|
          person_map[person].concat(durations)
        end
      end

      @by_date_person_summary[date_key] =
        person_map
          .sort_by { |person, _| person.name.downcase }
          .map do |person, durations|
            visits = durations.size
            avg = visits.positive? ? (durations.sum.to_f / visits).round : 0
            { person: person, average: avg, visits: visits }
          end

      per_person_avgs = person_map.values.map do |durations|
        visits = durations.size
        visits.positive? ? (durations.sum.to_f / visits) : 0.0
      end

      people_count = person_map.keys.size
      daily_avg_per_person =
        if people_count.positive?
          (per_person_avgs.sum / people_count).round
        else
          nil
        end

      @by_date_collective_average[date_key] = {
        avg_per_person: daily_avg_per_person,
        people_count: people_count
      }
    end

    @sorted_dates = @by_date_category_person.keys.sort.reverse
  end

  # GET /reports/people/:id/sign_ins
  # Optional params:
  # - from: YYYY-MM-DD
  # - to:   YYYY-MM-DD
  #
  # Shows each sign-in for a person with:
  # - actual duration,
  # - rolling average across all sign-ins (capped for calc),
  # - rolling average per program (capped for calc),
  # - per-program averages,
  # - highlight of first sign-in per program,
  # - tally of distinct programs joined at least once.
  def person_sign_ins
    @person = Person.find(params[:id])

    from_date = parse_date(params[:from])
    to_date   = parse_date(params[:to])

    range =
      if from_date && to_date
        from_date.beginning_of_day..to_date.end_of_day
      elsif from_date
        from_date.beginning_of_day..Time.current.end_of_day
      elsif to_date
        Time.at(0)..to_date.end_of_day
      else
        nil
      end

    sign_ins_scope = SignIn.where(person_id: @person.id).order(:arrived_at)
    sign_ins_scope = sign_ins_scope.where(arrived_at: range) if range
    @sign_ins = sign_ins_scope

    # Determine first sign-in per program for highlighting
    grouped_by_program = @sign_ins.group_by { |s| s.category_label || "Uncategorized" }
    @first_sign_in_ids_by_program = {}
    @program_first_seen_at = {}
    grouped_by_program.each do |program, sis|
      first = sis.select { |x| x.arrived_at.present? }.min_by(&:arrived_at)
      @first_sign_in_ids_by_program[program] = first&.id
      @program_first_seen_at[program] = first&.arrived_at
    end

    # Program stats (averages use capped durations)
    @program_stats =
      grouped_by_program.map do |program, sis|
        durations = sis.map(&:capped_duration_in_minutes)
        visits = durations.size
        avg = visits.positive? ? (durations.sum.to_f / visits).round : 0
        {
          program: program,
          visits: visits,
          average_minutes: avg,
          first_seen_at: @program_first_seen_at[program]
        }
      end.sort_by { |h| [h[:program] == "Uncategorized" ? 1 : 0, h[:program].to_s.downcase] }

    # Tally of distinct non-uncategorized programs joined at least once
    @distinct_programs_count = @program_stats.count { |h| h[:program] != "Uncategorized" && h[:visits] > 0 }

    # Build rows with:
    # - rolling average across all sign-ins
    # - rolling average per program
    cumulative_all = 0
    count_all = 0
    program_running = Hash.new { |h, k| h[k] = { sum: 0, count: 0 } }

    @rows = @sign_ins.map do |s|
      actual = s.duration_in_minutes
      capped = s.capped_duration_in_minutes
      program = s.category_label || "Uncategorized"

      # All-program rolling average
      count_all += 1
      cumulative_all += capped
      rolling_avg_all = (cumulative_all / count_all.to_f).round

      # Per-program rolling average
      program_running[program][:count] += 1
      program_running[program][:sum] += capped
      rolling_avg_program = (program_running[program][:sum] / program_running[program][:count].to_f).round

      {
        sign_in: s,
        program: program,
        actual_minutes: actual,
        rolling_avg_minutes: rolling_avg_all,           # across all programs
        program_rolling_avg_minutes: rolling_avg_program, # within this program
        first_in_program: (@first_sign_in_ids_by_program[program] == s.id)
      }
    end
  end

  private

  def parse_date(val)
    return nil if val.blank?
    Date.parse(val)
  rescue ArgumentError
    nil
  end
end
