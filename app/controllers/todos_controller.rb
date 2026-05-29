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
      respond_to do |format|
        format.json { render json: { id: @todo.id, redirect: root_path }, status: :created }
        format.any { redirect_to new_todo_path, notice: "Todo added." }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @todo.errors.full_messages }, status: :unprocessable_entity }
        format.any { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @todo.update(todo_params)
      respond_to do |format|
        format.json { head :ok }
        format.any { redirect_to root_path, notice: "Todo updated." }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @todo.errors.full_messages }, status: :unprocessable_entity }
        format.any { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @todo.destroy!
    respond_to do |format|
      format.json { head :no_content }
      format.any { redirect_to root_path, notice: "Todo deleted." }
    end
  end

  def toggle
    if @todo.complete?
      @todo.incomplete!
    else
      @todo.complete!
    end

    chain_context = complete_chain_step_and_build_context(@todo)
    respond_to do |format|
      format.json { render json: { completed_at: @todo.completed_at, chain: chain_context } }
      format.any { redirect_back fallback_location: root_path }
    end
  end

  private

  def set_todo
    @todo = current_user.todos.find(params[:id])
  end

  # Completes the chain item when the last step in a chain is checked off,
  # then returns a hash of chain context for the JSON response.
  # Only runs when the todo is being completed (not un-completed).
  def complete_chain_step_and_build_context(todo)
    return nil unless todo.complete?

    ci = todo.chain_item
    return nil unless ci

    ci.complete!
    next_ci = ci.chain.next_item_after(ci)
    if next_ci
      {
        chain_id: ci.chain_id,
        chain_item_id: next_ci.id,
        next_title: next_ci.title
      }
    else
      # Last item — mark the chain complete if all steps are done
      ci.chain.complete! if ci.chain.all_items_complete? && !ci.chain.complete?
      { chain_complete: true, chain_title: ci.chain.title }
    end
  end

  def todo_params
    params.require(:todo).permit(:title, :due_date, :project_id, :notes, :position)
  end
end
