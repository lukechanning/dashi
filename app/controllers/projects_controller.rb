class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]

  def index
    @show_all = params[:show_all].present?
    inactive_scope = current_user.projects.where.not(status: :active)

    @projects = current_user.projects.active.ordered.includes(:members, :goal)
    @inactive_count = inactive_scope.count
    @inactive_projects = inactive_scope.ordered.includes(:goal) if @show_all
  end

  def show
    @habits = @project.habits.ordered
    @todos = @project.todos.ordered
  end

  def new
    @project = current_user.projects.build(goal_id: params[:goal_id], title: params[:title])
    @from_todo = params[:from_todo]
  end

  def create
    @project = current_user.projects.build(project_params)

    if @project.save
      if params[:from_todo].present?
        todo = current_user.todos.find_by(id: params[:from_todo])
        todo&.discard!
      end
      respond_to do |format|
        format.json { render json: { id: @project.id, redirect: project_path(@project) }, status: :created }
        format.any { redirect_to @project, notice: "Project created." }
      end
    else
      @from_todo = params[:from_todo]
      respond_to do |format|
        format.json { render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity }
        format.any { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    prev_status = @project.status
    if @project.update(project_params)
      if @project.completed? && prev_status != "completed"
        chain = @project.chain_item&.chain
        celebration_msg = if chain&.complete?
          "Chain \"#{chain.title}\" complete! 🎉"
        else
          "\"#{@project.title}\" completed!"
        end
        flash[:celebration] = celebration_msg
        redirect_to projects_path
      elsif !@project.active? && prev_status == "active"
        redirect_to projects_path, notice: "Project archived."
      else
        redirect_to @project, notice: "Project updated."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.discard!
    redirect_to @project.goal || projects_path, notice: "Project deleted."
  end

  private

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:title, :description, :emoji, :goal_id, :status, :position)
  end
end
