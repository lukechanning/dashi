class DailyController < ApplicationController
  def show
    @daily_page = DailyPage.find_or_create_for(current_user)
    @todos = @daily_page.todos.ordered
    @overdue_todos = @daily_page.overdue_todos.ordered
  end
end
