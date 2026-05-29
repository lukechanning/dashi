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
      @todos = current_user.todos.visible_on(@date).ordered
                            .includes(:habit, project: :members, chain_item: { chain: { chain_items: :target_project } })
    end

    @upcoming_count = current_user.todos.incomplete.where(due_date: (Date.current + 1)..).count
    @done_count = current_user.todos.completed_on(Date.current).count
    @stale_todos = if !@viewing_history && current_user.show_stale_banner? && !stale_banner_dismissed?
                     current_user.todos.stale(current_user.stale_threshold_days).ordered.includes(:project)
    else
                     []
    end

    if !@viewing_history && @date.friday? && current_user.show_reflection_banner? && !reflection_banner_dismissed?
      week_start = @date.beginning_of_week(current_user.week_start_day_sym)
      week_completed = current_user.todos.where(habit_id: nil).complete
                                   .where(completed_at: week_start.beginning_of_day..@date.end_of_day)
      all_incomplete = current_user.todos.where(habit_id: nil).incomplete.ordered
      @show_reflection = true
      @week_stats = { completed: week_completed.count, incomplete: all_incomplete.count }
      @week_incomplete_todos = all_incomplete
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
