# app/controllers/incidents_controller.rb
class IncidentsController < ApplicationController
  def new
    @incident = Incident.new
  end

  def create
    @incident = Incident.new(incident_params)
    if @incident.save
      IncidentMailer.new_incident_email(@incident).deliver_later
      redirect_to guests_path, notice: "Incident logged and email sent!"
    else
      render :new
    end
  end

  private

  def incident_params
    params.require(:incident).permit(:title, :description)
  end
end
