class GoalsController < ApplicationController
  before_action :set_goal, only: [ :show, :edit, :update, :destroy ]

  def index
    @show_all = params[:show_all].present?
    scope = @show_all ? current_user.goals : current_user.goals.active
    @goals = scope.ordered.includes(:members)
    @inactive_count = current_user.goals.where.not(status: :active).count unless @show_all
  end

  def show
    @show_all_projects = params[:show_all].present?
    base = @goal.projects
    @projects = (@show_all_projects ? base : base.active).ordered
    @inactive_projects_count = base.where.not(status: :active).count unless @show_all_projects
  end

  def new
    @goal = current_user.goals.build
  end

  def create
    @goal = current_user.goals.build(goal_params)

    if @goal.save
      respond_to do |format|
        format.json { render json: { id: @goal.id, redirect: goal_path(@goal) }, status: :created }
        format.any { redirect_to @goal, notice: "Goal created." }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @goal.errors.full_messages }, status: :unprocessable_entity }
        format.any { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    prev_status = @goal.status
    archiving_goal = goal_params[:status] == "archived"

    if update_goal_with_projects(archiving_goal)
      if @goal.completed? && prev_status != "completed"
        flash[:celebration] = "\"#{@goal.title}\" completed!"
        redirect_to goals_path
      elsif !@goal.active? && prev_status == "active"
        redirect_to goals_path, notice: "Goal archived."
      else
        redirect_to @goal, notice: "Goal updated."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.discard!
    redirect_to goals_path, notice: "Goal deleted."
  end

  private

  def set_goal
    @goal = current_user.goals.find(params[:id])
  end

  def goal_params
    params.require(:goal).permit(:title, :description, :emoji, :status, :position)
  end

  def update_goal_with_projects(archiving_goal)
    updated = false

    Goal.transaction do
      updated = @goal.update(goal_params)
      next unless updated

      archive_goal_projects_and_todos if archiving_goal
    end

    updated
  end

  def archive_goal_projects_and_todos
    now = Time.current

    @goal.projects.update_all(status: Project.statuses[:archived], updated_at: now)
    @goal.todos.incomplete.find_each(&:discard!)
  end
end
