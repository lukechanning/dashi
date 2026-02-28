class InvitationsController < ApplicationController
  before_action :require_admin, only: [ :index, :new, :create ]
  skip_before_action :authenticate_user!, only: [ :accept, :register ]

  layout "auth", only: [ :accept, :register ]

  def index
    @invitations = Invitation.order(created_at: :desc)
  end

  def new
    @invitation = Invitation.new
  end

  def create
    @invitation = current_user.invitations.build(invitation_params)

    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_later
      redirect_to invitations_path, notice: "Invitation sent to #{@invitation.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def accept
    @invitation = Invitation.pending.find_by!(token: params[:token])
  end

  def register
    @invitation = Invitation.pending.find_by!(token: params[:token])

    @user = User.new(registration_params.merge(email: @invitation.email))

    if @user.save
      @invitation.accept!
      sign_in(@user)
      redirect_to root_path, notice: "Welcome to Dashi!"
    else
      render :accept, status: :unprocessable_entity
    end
  end

  private

  def require_admin
    redirect_to root_path, alert: "Not authorized." unless current_user.admin?
  end

  def invitation_params
    params.require(:invitation).permit(:email)
  end

  def registration_params
    params.require(:user).permit(:name)
  end
end
