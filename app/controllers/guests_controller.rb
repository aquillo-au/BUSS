class GuestsController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!, only: [ :history, :export ]
  before_action :auto_logout_overdue
  before_action :set_person, only: [ :edit, :update, :destroy, :arrive, :archive, :unarchive ]

  def index
    @people = Person.all
    @not_present = Person.where(present: false, archived: false).order(:name)
    @present_sign_ins = SignIn.joins(:person).where(left_at: nil, people: { archived: false }).order("people.name")
    @new_person = Person.new
    today = Time.zone.today
    @todays_unique_people_count =
      SignIn.where(arrived_at: today.beginning_of_day..today.end_of_day)
            .distinct
            .count(:person_id)
  end



  def create
  attrs = person_params
  candidate = find_existing_candidate(attrs)

  if candidate
    # If archived, unarchive and update details as before...
    if candidate.archived?
      updates = {}
      updates[:email] = attrs[:email] if candidate.email.blank? && attrs[:email].present?
      updates[:phone] = attrs[:phone] if candidate.phone.blank? && attrs[:phone].present?
      updates[:volunteer] = attrs[:volunteer] if candidate.volunteer.nil? && attrs.key?(:volunteer)
      updates[:archived] = false

      candidate.update!(updates) unless updates.empty?
      @new_person = candidate

      # Sign them in
      SignIn.create!(person: @new_person, arrived_at: Time.current)
      @new_person.present!

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to guests_path, notice: "#{@new_person.name} was unarchived and signed in." }
      end
      return
    else
      # Non-archived person: just sign them in!
      @new_person = candidate
      SignIn.create!(person: @new_person, arrived_at: Time.current)
      @new_person.present!

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to guests_path, notice: "#{@new_person.name} was already in the system. Signed in!" }
      end
      return
    end
  end

  # Default: create a new person
  @new_person = Person.new(attrs)
  respond_to do |format|
    if @new_person.save
      SignIn.create!(person: @new_person, arrived_at: Time.current)
      @new_person.present!
      format.turbo_stream
      format.html { redirect_to guests_path, notice: "#{@new_person.name} added and signed in." }
    else
      format.turbo_stream { render turbo_stream: turbo_stream.replace("new_person_errors", partial: "new_person_errors") }
      format.html { render :index, status: :unprocessable_entity }
    end
  end
end


  def edit
  end

  def merge
    @person = Person.find(params[:id])
    target = Person.find(params[:merge_with_id])
    target.merge_with!(@person)
    redirect_to edit_guest_path(target), notice: "Merged successfully!"
  end


  def update
    if @person.update(person_params)
      redirect_to guests_path, notice: "Person updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @person.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to guests_path, notice: "Person deleted." }
    end
  end

  def arrive
    @person = Person.find(params[:id])

    # Unarchive if signing in
    @person.update!(archived: false)

    @sign_in = SignIn.create!(person: @person, arrived_at: Time.current)
    @person.present!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to guests_path, notice: "#{@person.name} signed in." }
    end
  end

  def history
    # Determine time period from params (default: current year)
    period = params[:period] || "year"

    case period
    when "year"
      start_date = Time.current.beginning_of_year
      @period_label = "This Year"
    when "6_months"
      start_date = 6.months.ago
      @period_label = "Last 6 Months"
    when "12_months"
      start_date = 12.months.ago
      @period_label = "Last 12 Months"
    when "all_time"
      start_date = SignIn.where(is_haven_checkin: false).minimum(:arrived_at) || 100.years.ago
      @period_label = "All Time"
    when "previous_year"
      year = params[:year]&.to_i || Time.current.year - 1
      start_date = Date.new(year, 1, 1).beginning_of_day
      end_date = Date.new(year, 12, 31).end_of_day
      @period_label = year.to_s
    else
      start_date = Time.current.beginning_of_year
      @period_label = "This Year"
    end

    # Build the query
    if period == "previous_year"
      sign_ins = SignIn.includes(:person).where(is_haven_checkin: false).where(arrived_at: start_date..end_date).order(arrived_at: :desc)
    else
      sign_ins = SignIn.includes(:person).where(is_haven_checkin: false).where("arrived_at >= ?", start_date).order(arrived_at: :desc)
    end

    @people = Person.all
    @period = period
    @available_years = SignIn.where(is_haven_checkin: false).where.not(arrived_at: nil)
                            .pluck(:arrived_at).map(&:year).uniq.sort.reverse

    # Group sign-ins and notes by calendar day (local time)
    sign_ins_by_date = sign_ins.group_by { |s| s.arrived_at&.to_date }.reject { |day, _| day.nil? }
    notes = Note.order(created_at: :desc)
    notes_by_date = notes.group_by { |n| n.created_at.to_date }

    # Union of all days that have either sign-ins or notes
    days = (sign_ins_by_date.keys + notes_by_date.keys).uniq.sort.reverse

    # Build summaries per day
    @day_summaries = days.map do |day|
      day_sign_ins = sign_ins_by_date[day] || []
      unique_people_count = day_sign_ins.map(&:person_id).uniq.size

      day_notes = notes_by_date[day] || []
      notes_total = day_notes.sum { |n| n.amount.to_i }

      meals_served = unique_people_count + notes_total

      {
        day: day,
        sign_ins: day_sign_ins,
        unique_people_count: unique_people_count,
        notes: day_notes,
        notes_total: notes_total,
        meals_served: meals_served
      }
    end

  # Build chart data for program trends
  chart_category_order = [
    "Frypan Warriors", "Working Group", "Bible Study", "Board Meetings",
    "Smart Lunch", "Activities", "Bathurst Buddies", "Community Gardens",
    "Music BUSS", "Cafe", "Misc/Unknown"
  ]

  # Use monthly grouping for longer periods, weekly for shorter ones
  use_monthly = period == "12_months" || period == "previous_year" || period == "all_time"

  by_program = sign_ins.to_a.reject { |s| s.arrived_at.nil? }.group_by(&:category_label)

  @avg_time_chart_data = []
  @attendees_chart_data = []

  # Calculate overall average time across all programs
  all_durations = []
  all_attendee_periods = {}

  chart_category_order.each do |cat|
    items = by_program[cat]
    next if items.blank?

    if use_monthly
      grouped = items.group_by { |s| s.arrived_at.beginning_of_month.to_date }
    else
      grouped = items.group_by { |s| s.arrived_at.beginning_of_week(:monday).to_date }
    end

    avg_data = {}
    attendees_data = {}

    grouped.sort.each do |period_start, period_items|
      label = use_monthly ? period_start.strftime("%b %Y") : period_start.strftime("%b %d")

      period_avg = (period_items.sum { |s| s.capped_duration_in_minutes } / period_items.size.to_f).round
      avg_data[label] = period_avg

      # Track for overall average
      all_durations.concat(period_items.map { |s| s.capped_duration_in_minutes })
      all_attendee_periods[label] ||= 0
      all_attendee_periods[label] += period_items.map(&:person_id).compact.uniq.size

      attendees_data[label] = period_items.map(&:person_id).compact.uniq.size
    end

    @avg_time_chart_data << { name: cat, data: avg_data }
    @attendees_chart_data << { name: cat, data: attendees_data }
  end

  # Calculate overall average line
  overall_avg = all_durations.any? ? (all_durations.sum.to_f / all_durations.size).round : 0
  overall_avg_data = {}

  # Build overall average data for each period
  if use_monthly
    sign_ins.to_a.reject { |s| s.arrived_at.nil? }.group_by { |s| s.arrived_at.beginning_of_month.to_date }.sort.each do |period_start, period_items|
      label = period_start.strftime("%b %Y")
      overall_avg_data[label] = (period_items.sum { |s| s.capped_duration_in_minutes } / period_items.size.to_f).round
    end
  else
    sign_ins.to_a.reject { |s| s.arrived_at.nil? }.group_by { |s| s.arrived_at.beginning_of_week(:monday).to_date }.sort.each do |period_start, period_items|
      label = period_start.strftime("%b %d")
      overall_avg_data[label] = (period_items.sum { |s| s.capped_duration_in_minutes } / period_items.size.to_f).round
    end
  end

  @avg_time_chart_data << { name: "Overall Average", data: overall_avg_data }
  end

  def archive
    @person.update!(archived: true, present: false)
    redirect_back fallback_location: history_guests_path, notice: "#{@person.name} archived."
  end

  def unarchive
    @person.update!(archived: false)
    redirect_back fallback_location: history_guests_path, notice: "#{@person.name} unarchived."
  end

  # GET /guests/export.xlsx
  def export
    period = params[:period] || "year"

    case period
    when "year"
      start_date = Time.current.beginning_of_year
      @period_label = "This Year"
    when "6_months"
      start_date = 6.months.ago
      @period_label = "Last 6 Months"
    when "12_months"
      start_date = 12.months.ago
      @period_label = "Last 12 Months"
    when "all_time"
      start_date = SignIn.where(is_haven_checkin: false).minimum(:arrived_at) || 100.years.ago
      @period_label = "All Time"
    when "previous_year"
      year = params[:year]&.to_i || Time.current.year - 1
      start_date = Date.new(year, 1, 1).beginning_of_day
      end_date = Date.new(year, 12, 31).end_of_day
      @period_label = year.to_s
    else
      start_date = Time.current.beginning_of_year
      @period_label = "This Year"
    end

    sign_ins =
      if period == "previous_year"
        SignIn.includes(:person).where(is_haven_checkin: false).where(arrived_at: start_date..end_date)
      else
        SignIn.includes(:person).where(is_haven_checkin: false).where("arrived_at >= ?", start_date)
      end

    @period = period

    program_order = [
      "Frypan Warriors", "Working Group", "Bible Study", "Board Meetings",
      "Smart Lunch", "Activities", "Bathurst Buddies", "Community Gardens",
      "Music BUSS", "Cafe", "Misc/Unknown"
    ]

    grouped = sign_ins.to_a.group_by(&:category_label)
    @grouped_by_program = program_order.each_with_object({}) do |prog, hash|
      items = grouped[prog]
      hash[prog] = items if items.present?
    end
    # Include any labels not in the canonical order
    grouped.each do |label, items|
      @grouped_by_program[label] ||= items if items.present?
    end

    # When a specific category is requested, filter to just that one
    if params[:category].present?
      @grouped_by_program = @grouped_by_program.slice(params[:category])
    end

    respond_to do |format|
      format.xlsx do
        if params[:category].present?
          category_slug = params[:category].parameterize
          filename = "#{category_slug}-#{@period_label.parameterize}-#{Time.current.to_date}.xlsx"
        else
          filename = "programs-#{@period_label.parameterize}-#{Time.current.to_date}.xlsx"
        end
        response.headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
      end
    end
  end

  private

  def auto_logout_overdue
    SignIn.auto_logout_overdue!
  end

  def set_person
    @person = Person.find(params[:id])
  end

  def person_params
    params.require(:person).permit(:name, :email, :phone, :volunteer)
  end

  # Prefer matching by email, then phone, then name.
  # Email and name matches are case-insensitive.
  def find_existing_candidate(attrs)
    if attrs[:email].present?
      person = Person.where("LOWER(email) = ?", attrs[:email].downcase).first
      return person if person
    end

    if attrs[:phone].present?
      person = Person.where(phone: attrs[:phone]).first
      return person if person
    end

    if attrs[:name].present?
      return Person.where("LOWER(name) = ?", attrs[:name].downcase).first
    end

    nil
  end
end
