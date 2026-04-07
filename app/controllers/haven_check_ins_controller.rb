class HavenCheckInsController < ApplicationController
  before_action :authenticate_user!

  def index
    @sign_ins = SignIn.where(is_haven_checkin: true, checked_out_at: nil)
                      .includes(:person)
                      .order(checked_in_at: :asc)
  end

  def new
    @sign_in = SignIn.new
    @person = Person.new
  end

  def create
    name = params[:haven_check_in][:name]&.strip
    phone = params[:haven_check_in][:phone]&.strip

    person = find_or_create_person(name, phone)

    unless person
      flash[:alert] = "Name is required."
      @sign_in = SignIn.new
      @person = Person.new
      render :new, status: :unprocessable_entity
      return
    end

    @sign_in = SignIn.new(
      person: person,
      is_haven_checkin: true,
      checked_in_at: Time.current,
      has_car: params[:haven_check_in][:has_car] == "1",
      num_children: params[:haven_check_in][:num_children].to_i,
      has_pet: params[:haven_check_in][:has_pet] == "1",
      haven_notes: params[:haven_check_in][:haven_notes]
    )

    if @sign_in.save
      person.present!
      redirect_to haven_check_ins_path, notice: "#{person.name} checked into the Haven."
    else
      @person = person
      render :new, status: :unprocessable_entity
    end
  end

  def sign_out
    @sign_in = SignIn.where(is_haven_checkin: true, checked_out_at: nil).find(params[:id])
    @sign_in.update!(checked_out_at: Time.current)
    redirect_to haven_check_ins_path, notice: "#{@sign_in.person.name} has been signed out of the Haven."
  end

  private

  def find_or_create_person(name, phone)
    return nil if name.blank?

    person = Person.where("LOWER(name) = ?", name.downcase).first
    person ||= Person.where(phone: phone).first if phone.present?

    if person
      person.update!(archived: false) if person.archived?
      person.update!(phone: phone) if phone.present? && person.phone.blank?
      person
    else
      Person.create!(name: name, phone: phone.presence)
    end
  end
end
