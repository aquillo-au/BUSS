class NotesController < ApplicationController
  def new
    @note = Note.new
  end

  def create
    @note = Note.new(note_params)
    if @note.save
      redirect_to guests_path, notice: "note logged"
    else
      render :new
    end
  end

  private

  def note_params
    params.require(:note).permit(:info, :amount)
  end
end
