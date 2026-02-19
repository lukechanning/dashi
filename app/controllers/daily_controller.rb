class DailyController < ApplicationController
  def show
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @date = Date.current if @date > Date.current
    @viewing_history = @date < Date.current

    @daily_page = DailyPage.find_or_create_for(current_user, @date)
    @todos = @daily_page.todos.ordered.includes(project: :members)
    @overdue_todos = @viewing_history ? [] : @daily_page.overdue_todos.ordered.includes(project: :members)
    @scheduled_count = current_user.todos.incomplete.where(due_date: (Date.current + 1)..).count
    @all_count = current_user.todos.incomplete.count
  end
end
