class SignInsController < ApplicationController
  def leave
    @sign_in = SignIn.find(params[:id])

    unless @sign_in.left_at.present?
      @sign_in.update!(left_at: Time.current)

      # If the person has no other active sign-ins, mark them not present
      unless SignIn.exists?(person_id: @sign_in.person_id, left_at: nil)
        @sign_in.person.update!(present: false)
      end
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path, notice: "#{@sign_in.person.name} signed out." }
    end
  end

  def destroy
    @sign_in = SignIn.find(params[:id])
    person = @sign_in.person
    was_active = @sign_in.left_at.nil?

    @sign_in.destroy!

    # If we deleted an active sign-in and there are no other active ones, clear present flag
    if was_active && !SignIn.exists?(person_id: person.id, left_at: nil)
      person.update_columns(present: false, updated_at: Time.current)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to history_guests_path, notice: "Sign-in deleted." }
    end
  end
end
