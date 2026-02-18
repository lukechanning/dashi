class DailyController < ApplicationController
  def show
    @daily_page = DailyPage.find_or_create_for(current_user)
    @todos = @daily_page.todos.ordered
    @overdue_todos = @daily_page.overdue_todos.ordered
    @scheduled_count = current_user.todos.incomplete.where(due_date: (Date.current + 1)..).count
    @all_count = current_user.todos.incomplete.count
  end
end
