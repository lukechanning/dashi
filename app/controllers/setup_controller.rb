class SetupController < ApplicationController
  layout "auth"

  skip_before_action :authenticate_user!
  before_action :redirect_if_users_exist

  def show
    @user = User.new
  end

  def create
    @user = User.new(setup_params.merge(admin: true))
    if @user.save
      sign_in(@user)
      redirect_to root_path, notice: "Welcome to Dashi! You're set up as admin."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_users_exist
    redirect_to root_path if User.exists?
  end

  def setup_params
    params.require(:user).permit(:name, :email)
  end
end
