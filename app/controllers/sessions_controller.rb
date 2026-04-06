class SessionsController < ApplicationController
  # Dummy digest used to perform a constant-time BCrypt check even when the
  # requested username does not exist, mitigating user-enumeration via timing.
  FAKE_DIGEST = BCrypt::Password.create("fake_password_for_timing_safety")

  def new
    redirect_to root_path if user_signed_in?
  end

  def create
    user = User.find_by(username: params[:username].to_s.strip.downcase)
    # Always run a BCrypt comparison to prevent timing-based username enumeration
    authenticated = user ? user.authenticate(params[:password]) : BCrypt::Password.new(FAKE_DIGEST).is_password?(params[:password])

    if user && authenticated
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in successfully."
    else
      flash.now[:alert] = "Invalid username or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "Logged out successfully."
  end
end
