class HabitsController < ApplicationController
  before_action :set_habit, only: [ :edit, :update, :destroy, :toggle_active ]

  def index
    @active_habits = current_user.habits.active.ordered
    @paused_habits = current_user.habits.paused.ordered
  end

  def new
    @habit = current_user.habits.build(project_id: params[:project_id])
  end

  def create
    @habit = current_user.habits.build(habit_params)

    if @habit.save
      @habit.generate_todo_for!(Date.current)
      redirect_to habits_path, notice: "Habit created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @habit.update(habit_params)
      redirect_to habits_path, notice: "Habit updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @habit.destroy!
    redirect_to habits_path, notice: "Habit deleted."
  end

  def toggle_active
    if @habit.active?
      @habit.pause!
    else
      @habit.resume!
      @habit.generate_todo_for!(Date.current)
    end
    redirect_to habits_path, notice: @habit.active? ? "Habit resumed." : "Habit paused."
  end

  private

  def set_habit
    @habit = current_user.habits.find(params[:id])
  end

  def habit_params
    permitted = params.require(:habit).permit(:title, :frequency, :project_id, :start_date, days_of_week: [])
    if permitted[:days_of_week].is_a?(Array)
      permitted[:days_of_week] = permitted[:days_of_week].reject(&:blank?).join(",")
    end
    permitted
  end
end
