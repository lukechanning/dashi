class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  prepend_before_action :redirect_to_setup_if_needed
  around_action :set_user_timezone
  before_action :set_wizard_data

  private

  def redirect_to_setup_if_needed
    return if controller_name.in?(%w[setup sessions invitations])
    return if User.exists?
    redirect_to setup_path
  end

  def set_user_timezone(&block)
    timezone = current_user&.timezone.presence || "UTC"
    Time.use_zone(timezone, &block)
  end

  # Preloads data for the creation wizard partial rendered in the layout.
  # Runs once per request so the partial doesn't query on every page load.
  def set_wizard_data
    return unless current_user

    @wizard_projects = current_user.projects.active.ordered
    @wizard_goals = current_user.goals.active.ordered
  end
end
