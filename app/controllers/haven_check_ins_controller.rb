class HavenCheckInsController < ApplicationController
  before_action :authenticate_user!

  def new
    @sign_in = SignIn.new(arrived_at: Time.current)
    @people = Person.where(archived: false).order(:name)
  end

  def create
    @sign_in = SignIn.new(haven_check_in_params)
    @sign_in.is_haven_checkin = true

    if @sign_in.save
      @sign_in.person.present!
      redirect_to haven_check_ins_path, notice: "#{@sign_in.person.name} checked into the Haven."
    else
      @people = Person.where(archived: false).order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def index
    @haven_check_ins = SignIn.includes(:person)
                             .where(is_haven_checkin: true)
                             .order(arrived_at: :desc)
  end

  def leave
    @sign_in = SignIn.find(params[:id])

    unless @sign_in.left_at.present?
      @sign_in.update!(left_at: Time.current)

      unless SignIn.exists?(person_id: @sign_in.person_id, left_at: nil)
        @sign_in.person.update!(present: false)
      end
    end

    redirect_to haven_check_ins_path, notice: "#{@sign_in.person.name} signed out of the Haven."
  end

  private

  def haven_check_in_params
    params.require(:sign_in).permit(
      :person_id,
      :arrived_at,
      :phone_number,
      :car,
      :children,
      :pet,
      :notes
    )
  end
end
