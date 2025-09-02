class GuestsController < ApplicationController
  before_action :set_person, only: [:edit, :update, :destroy, :arrive]

  def index
    @people = Person.all
    @not_present = Person.where(present: false).order(:name)
    @present_sign_ins = SignIn.joins(:person).where(left_at: nil).order('people.name')
    @new_person = Person.new
  end

  def create
    @new_person = Person.new(person_params)

    respond_to do |format|
      if @new_person.save
        # Auto sign in
        sign_in = SignIn.create!(person: @new_person, arrived_at: Time.current)
        @new_person.present!

        format.turbo_stream
        format.html { redirect_to guests_path, notice: "#{@new_person.name} added and signed in." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_person_errors", partial: "new_person_errors") }
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @person.update(person_params)
      redirect_to guests_path, notice: "Person updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @person.destroy
    respond_to do |format|
      format.turbo_stream # will render destroy.turbo_stream.erb
      format.html { redirect_to guests_path, notice: "Person deleted." }
    end
  end

  def arrive
    @person = Person.find(params[:id])
    @sign_in = SignIn.create!(person: @person, arrived_at: Time.current)
    @person.present!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to guests_path, notice: "#{@person.name} signed in." }
    end
  end

  def history
    @sign_ins = SignIn.includes(:person).order(created_at: :desc)
  end

  private

  def set_person
    @person = Person.find(params[:id])
  end

  def person_params
    params.require(:person).permit(:name)
  end
end
