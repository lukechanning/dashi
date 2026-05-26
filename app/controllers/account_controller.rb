class AccountController < ApplicationController
  def show
  end

  def update
    if current_user.update(preference_params)
      respond_to do |format|
        format.turbo_stream { head :no_content }
        format.html { redirect_to account_path, notice: "Settings saved" }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_content }
        format.html { render :show, status: :unprocessable_content }
      end
    end
  end

  private

  def preference_params
    params.require(:user).permit(
      :show_stale_banner,
      :show_reflection_banner,
      :stale_threshold_days,
      :week_start_day
    )
  end
end
