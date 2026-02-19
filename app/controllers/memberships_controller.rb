class MembershipsController < ApplicationController
  before_action :set_memberable

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    unless user
      redirect_to @memberable, alert: "No user found with that email address."
      return
    end

    if user == @memberable.user
      redirect_to @memberable, alert: "The owner is already a member."
      return
    end

    membership = @memberable.memberships.new(user: user, role: :member)

    if membership.save
      redirect_to @memberable, notice: "#{user.name} added as a member."
    else
      redirect_to @memberable, alert: membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    membership = @memberable.memberships.find(params[:id])
    membership.destroy
    redirect_to @memberable, notice: "Member removed."
  end

  private

  def set_memberable
    if params[:goal_id]
      @memberable = current_user.goals.find(params[:goal_id])
    elsif params[:project_id]
      @memberable = current_user.projects.find(params[:project_id])
    end
  end
end
