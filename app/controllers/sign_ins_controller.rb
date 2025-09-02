class SignInsController < ApplicationController
  before_action :set_sign_in, only: [:leave]

  def leave
    @sign_in = SignIn.find(params[:id])
    @person = @sign_in.person
    @sign_in.update!(left_at: Time.current)
    @person.absent!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to guests_path, notice: "#{@person.name} signed out" }
    end
  end
  private

  def set_sign_in
    @sign_in = SignIn.find(params[:id])
  end
end
