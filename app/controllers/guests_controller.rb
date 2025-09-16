class GuestsController < ApplicationController
  before_action :auto_logout_overdue
  before_action :set_person, only: [:edit, :update, :destroy, :arrive, :archive, :unarchive]

  def index
    @people = Person.all
    @not_present = Person.where(present: false, archived: false).order(:name)
    @present_sign_ins = SignIn.joins(:person).where(left_at: nil, people: { archived: false }).order('people.name')
    @new_person = Person.new
  end


  def create
    # Try to find an archived person that matches the submitted info.
    attrs = person_params
    candidate = find_existing_candidate(attrs)

    if candidate&.archived?
      # Backfill any missing fields on the archived person with the newly submitted details.
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
    end

  def edit
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
    @sign_ins = SignIn.includes(:person).order(arrived_at: :desc)
    @people = Person.all
    @grouped_sign_ins = {
      "Frypan Warriors" => @sign_ins.select { |s| s.arrived_at.monday? },
      "Smart Lunch" => @sign_ins.select { |s| s.arrived_at.wednesday? },
      "Bathurst Buddies" => @sign_ins.select { |s| s.arrived_at.friday? },
      "Cafe" => @sign_ins.select { |s| s.arrived_at.saturday? || s.arrived_at.sunday? }
    }
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

  def auto_logout_overdue
    SignIn.auto_logout_overdue!
  end

  def set_person
    @person = Person.find(params[:id])
  end

  def person_params
    params.require(:person).permit(:name, :email, :phone, :volunteer)
  end
end
