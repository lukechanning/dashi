class NotesController < ApplicationController
  before_action :set_notable
  before_action :set_note, only: [:edit, :update, :destroy]

  def create
    @note = @notable.notes.build(note_params.merge(user: current_user))

    if @note.save
      redirect_back fallback_location: root_path, notice: "Note added."
    else
      redirect_back fallback_location: root_path, alert: "Note can't be blank."
    end
  end

  def edit
  end

  def update
    if @note.update(note_params)
      redirect_back fallback_location: root_path, notice: "Note updated."
    else
      redirect_back fallback_location: root_path, alert: "Note can't be blank."
    end
  end

  def destroy
    @note.destroy!
    redirect_back fallback_location: root_path, notice: "Note deleted."
  end

  private

  def set_notable
    if params[:goal_id]
      @notable = current_user.goals.find(params[:goal_id])
    elsif params[:project_id]
      @notable = current_user.projects.find(params[:project_id])
    elsif params[:todo_id]
      @notable = current_user.todos.find(params[:todo_id])
    elsif params[:daily_page_id]
      @notable = current_user.daily_pages.find(params[:daily_page_id])
    end
  end

  def set_note
    @note = @notable.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:body)
  end
end
