# app/mailers/incident_mailer.rb
class IncidentMailer < ApplicationMailer
  default to: "buss2795@gmail.com", from: "aquillosalt@gmail.com"

  def new_incident_email(incident)
    @incident = incident
    mail(
      subject: "New Incident Logged: #{@incident.title}"
    )
  end
end
