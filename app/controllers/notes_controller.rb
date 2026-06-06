class NotesController < ApplicationController
  include PolymorphicParent

  before_action :set_notable, only: [ :create, :edit, :update, :destroy ]
  before_action :set_note, only: [ :edit, :update, :destroy ]

  def index
    @notes = current_user.notes.includes(:notable).order(created_at: :desc)
  end

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
    @note.discard!
    redirect_back fallback_location: root_path, notice: "Note deleted."
  end

  private

  def set_notable
    @notable = find_parent(goal: :goals, project: :projects, todo: :todos, daily_page: :daily_pages)
  end

  def set_note
    @note = @notable.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:body)
  end
end
