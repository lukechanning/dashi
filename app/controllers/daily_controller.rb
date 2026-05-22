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
    @done_count = current_user.todos.completed_on(Date.current).count
    @stale_todos = if !@viewing_history && !stale_banner_dismissed?
                     current_user.todos.stale.ordered.includes(:project)
                   else
                     []
                   end

    if !@viewing_history && @date.friday? && !reflection_banner_dismissed?
      week_start = @date.beginning_of_week
      week_todos = current_user.todos.where(habit_id: nil, due_date: week_start..@date)
      @show_reflection = true
      @week_stats = { completed: week_todos.complete.count, incomplete: week_todos.incomplete.count }
      @week_incomplete_todos = week_todos.incomplete.ordered
    end
  end

  private

  def reflection_banner_dismissed?
    cookies.signed[:reflection_dismissed_on] == Date.current.to_s
  end

  def stale_banner_dismissed?
    cookies.signed[:stale_dismissed_on] == Date.current.to_s
  end
end
