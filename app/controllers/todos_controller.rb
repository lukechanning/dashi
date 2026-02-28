class TodosController < ApplicationController
  before_action :set_todo, only: [ :edit, :update, :destroy, :toggle ]

  def new
    @todo = current_user.todos.build(
      project_id: params[:project_id],
      due_date: params[:due_date] || Date.current
    )
  end

  def create
    @todo = current_user.todos.build(todo_params)

    if @todo.save
      redirect_back fallback_location: root_path, notice: "Todo added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @todo.update(todo_params)
      redirect_back fallback_location: root_path, notice: "Todo updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @todo.destroy!
    redirect_back fallback_location: root_path, notice: "Todo deleted."
  end

  def toggle
    if @todo.complete?
      @todo.incomplete!
    else
      @todo.complete!
    end

    redirect_back fallback_location: root_path
  end

  private

  def set_todo
    @todo = current_user.todos.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :due_date, :project_id, :notes, :position)
  end
end
