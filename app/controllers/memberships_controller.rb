class MembershipsController < ApplicationController
  include PolymorphicParent

  before_action :set_memberable

  def suggestions
    query = params[:q].to_s.strip.downcase
    return render json: [] if query.length < 2

    existing_member_ids = [ @memberable.user_id ] + @memberable.memberships.pluck(:user_id)
    pattern = "%#{User.sanitize_sql_like(query)}%"
    users = User.where.not(id: existing_member_ids)
                .where("LOWER(name) LIKE :query OR LOWER(email) LIKE :query", query: pattern)
                .order(:name, :email)
                .limit(8)

    render json: users.map { |user| { name: user.name, email: user.email } }
  end

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
    @memberable = find_parent(goal: :goals, project: :projects)
  end
end
