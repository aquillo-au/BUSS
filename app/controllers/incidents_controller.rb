class IncidentsController < ApplicationController
  before_action :set_incident, only: [:destroy]

  def index
    @incidents = Incident.order(created_at: :desc)
  end

  def new
    @incident = Incident.new
  end

  def create
    @incident = Incident.new(incident_params)
    if @incident.save
      redirect_to incidents_path, notice: "Incident logged."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @incident.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to incidents_path, notice: "Incident deleted." }
    end
  end

  private

  def set_incident
    @incident = Incident.find(params[:id])
  end

  def incident_params
    params.require(:incident).permit(:title, :description)
  end
end
