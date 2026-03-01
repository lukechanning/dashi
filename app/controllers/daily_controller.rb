class DailyController < ApplicationController
  def show
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @date = Date.current if @date > Date.current
    @viewing_history = @date < Date.current

    @daily_page = DailyPage.find_or_create_for(current_user, @date)

    if @viewing_history
      @todos = @daily_page.history_todos.ordered.includes(:habit, project: :members)
    else
      current_user.generate_habit_todos_for(@date)
      @todos = current_user.todos.visible_on(@date).ordered.includes(:habit, project: :members)
    end

    @upcoming_count = current_user.todos.incomplete.where(due_date: (Date.current + 1)..).count
    @all_count = current_user.todos.incomplete.count
  end
end
