class SessionsController < ApplicationController
  def new
    redirect_to root_path if user_signed_in?
  end

  def create
    user = User.find_by(username: params[:username].to_s.strip.downcase)
    if user&.authenticate(params[:password])
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
