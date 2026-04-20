class ReportsController < ApplicationController
  before_action :authenticate_user!

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
  # - period: year|6_months|12_months|previous_year (period filter buttons)
  # - year: YYYY (for previous_year period)
  # - from: YYYY-MM-DD (custom date range)
  # - to:   YYYY-MM-DD (custom date range)
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

    # Period filter (same as history page)
    period = params[:period]
    @period = period
    @available_years = SignIn.where(person_id: @person.id).where.not(arrived_at: nil)
                             .pluck(:arrived_at).map(&:year).uniq.sort.reverse

    if period.present?
      case period
      when "year"
        start_date = Time.current.beginning_of_year
        end_date   = nil
        @period_label = "This Year"
      when "6_months"
        start_date = 6.months.ago
        end_date   = nil
        @period_label = "Last 6 Months"
      when "12_months"
        start_date = 12.months.ago
        end_date   = nil
        @period_label = "Last 12 Months"
      when "previous_year"
        year = params[:year]&.to_i || Time.current.year - 1
        start_date = Date.new(year, 1, 1).beginning_of_day
        end_date   = Date.new(year, 12, 31).end_of_day
        @period_label = year.to_s
      else
        start_date = Time.current.beginning_of_year
        end_date   = nil
        @period_label = "This Year"
      end

      range = end_date ? start_date..end_date : start_date..Time.current.end_of_day
    else
      # Fall back to custom from/to date range
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
    end

    sign_ins_scope = SignIn.where(person_id: @person.id).order(:arrived_at)
    sign_ins_scope = sign_ins_scope.where(arrived_at: range) if range
    @sign_ins = sign_ins_scope

    @activity_sign_ins  = @sign_ins.select(&:activity?)
    @program_sign_ins   = @sign_ins.reject(&:activity?)

    grouped_by_program = @program_sign_ins.group_by { |s| s.category_label || "Uncategorized" }

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
      end.sort_by { |h| [ h[:program] == "Uncategorized" ? 1 : 0, h[:program].to_s.downcase ] }

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

    # Weekly average time chart data (only non-activity sign-ins with arrived_at)
    valid_sign_ins = @sign_ins.to_a.reject { |s| s.arrived_at.nil? }
    weeks = valid_sign_ins.group_by { |s| s.arrived_at.beginning_of_week(:monday).to_date }
    @weekly_chart_data = weeks.sort.map do |week_start, week_sis|
      avg = (week_sis.sum { |s| s.capped_duration_in_minutes } / week_sis.size.to_f).round
      [ week_start.strftime("%b %d"), avg ]
    end.to_h

    # Trend calculation (requires at least 4 data points)
    if @weekly_chart_data.size >= 4
      values = @weekly_chart_data.values
      half = values.size / 2
      first_half_avg = values.first(half).sum.to_f / half
      second_half_avg = values.last(half).sum.to_f / half
      if second_half_avg > first_half_avg * 1.05
        @trend_direction = "up"
      elsif second_half_avg < first_half_avg * 0.95
        @trend_direction = "down"
      else
        @trend_direction = "stable"
      end
    end

    # Summary stats
    all_durations = valid_sign_ins.map(&:capped_duration_in_minutes)
    @total_visits = all_durations.size
    @avg_minutes_per_visit = all_durations.present? ? (all_durations.sum.to_f / all_durations.size).round : 0
  end

  # GET /reports/people/:id/sign_ins/export.xlsx
  def person_sign_ins_export
    @person = Person.find(params[:id])

    period = params[:period]
    @period = period

    if period.present?
      case period
      when "year"
        start_date = Time.current.beginning_of_year
        end_date   = nil
        @period_label = "This Year"
      when "6_months"
        start_date = 6.months.ago
        end_date   = nil
        @period_label = "Last 6 Months"
      when "12_months"
        start_date = 12.months.ago
        end_date   = nil
        @period_label = "Last 12 Months"
      when "previous_year"
        year = params[:year]&.to_i || Time.current.year - 1
        start_date = Date.new(year, 1, 1).beginning_of_day
        end_date   = Date.new(year, 12, 31).end_of_day
        @period_label = year.to_s
      else
        start_date = Time.current.beginning_of_year
        end_date   = nil
        @period_label = "This Year"
      end

      range = end_date ? start_date..end_date : start_date..Time.current.end_of_day
    else
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
      @period_label = "Custom Range"
    end

    sign_ins_scope = SignIn.where(person_id: @person.id).order(:arrived_at)
    sign_ins_scope = sign_ins_scope.where(arrived_at: range) if range
    @sign_ins = sign_ins_scope

    @program_sign_ins = @sign_ins.reject(&:activity?)
    grouped_by_program = @program_sign_ins.group_by { |s| s.category_label || "Uncategorized" }

    @first_sign_in_ids_by_program = {}
    grouped_by_program.each do |program, sis|
      first = sis.select { |x| x.arrived_at.present? }.min_by(&:arrived_at)
      @first_sign_in_ids_by_program[program] = first&.id
    end

    # Build rows with rolling averages
    cumulative_all = 0
    count_all = 0
    program_running = Hash.new { |h, k| h[k] = { sum: 0, count: 0 } }

    @rows = @sign_ins.map do |s|
      actual = s.duration_in_minutes
      capped = s.capped_duration_in_minutes
      program = s.category_label || "Uncategorized"

      count_all += 1
      cumulative_all += capped
      rolling_avg_all = (cumulative_all / count_all.to_f).round

      program_running[program][:count] += 1
      program_running[program][:sum] += capped
      rolling_avg_program = (program_running[program][:sum] / program_running[program][:count].to_f).round

      {
        sign_in: s,
        program: program,
        actual_minutes: actual,
        rolling_avg_minutes: rolling_avg_all,
        program_rolling_avg_minutes: rolling_avg_program,
        first_in_program: (@first_sign_in_ids_by_program[program] == s.id)
      }
    end

    respond_to do |format|
      format.xlsx do
        person_slug = @person.name.parameterize
        period_slug = (@period_label || "all").parameterize
        filename = "#{person_slug}-sign-ins-#{period_slug}-#{Date.today}.xlsx"
        response.headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
      end
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
