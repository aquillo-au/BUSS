class GuestsController < ApplicationController
  before_action :auto_logout_overdue
  before_action :set_person, only: [:edit, :update, :destroy, :arrive, :archive, :unarchive]

  def index
    @people = Person.all
    @not_present = Person.where(present: false, archived: false).order(:name)
    @present_sign_ins = SignIn.joins(:person).where(left_at: nil, people: { archived: false }).order('people.name')
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
    # All sign-ins with associated people
    sign_ins = SignIn.includes(:person).order(arrived_at: :desc)
    @people   = Person.all
    # Group sign-ins and notes by calendar day (local time)
    sign_ins_by_date = sign_ins.group_by { |s| s.arrived_at.to_date }
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
  end

  def archive
    @person.update!(archived: true, present: false)
    redirect_back fallback_location: history_guests_path, notice: "#{@person.name} archived."
  end

  def unarchive
    @person.update!(archived: false)
    redirect_back fallback_location: history_guests_path, notice: "#{@person.name} unarchived."
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
