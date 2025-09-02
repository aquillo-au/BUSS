class VolunteersController < ApplicationController
  def index
    @volunteers = Person.where(volunteer: true)
    @new_volunteer = Person.new(volunteer: true)
  end

  def create
    # Case-insensitive search by name
    volunteer = Person.where("LOWER(name) = ?", volunteer_params[:name].downcase).first

    if volunteer
      # Update existing person
      volunteer.update(volunteer_params.merge(volunteer: true, present: true))
      redirect_to volunteers_path, notice: "#{volunteer.name} updated and signed in!"
    else
      # Create new volunteer
      @volunteer = Person.new(volunteer_params.merge(volunteer: true, present: true))
      if @volunteer.save
        redirect_to volunteers_path, notice: "Volunteer created and signed in!"
      else
        @volunteers = Person.where(volunteer: true)
        render :index, status: :unprocessable_entity
      end
    end
  end

  def arrive
    volunteer = Person.find(params[:id])
    volunteer.update(present: true, volunteer: true)
    SignIn.create!(person: volunteer, arrived_at: Time.current)
    redirect_to volunteers_path, notice: "#{volunteer.name} signed in!"
  end

  private

  def volunteer_params
    params.require(:person).permit(:name, :email, :phone)
  end
end
