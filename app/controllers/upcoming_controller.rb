class UpcomingController < ApplicationController
  def index
    todos = current_user.todos.incomplete
                        .where(due_date: (Date.current + 1)..)
                        .includes(project: :members)
                        .order(:due_date, :position)
    @todos_by_date = todos.group_by(&:due_date)
  end
end
