class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  prepend_before_action :redirect_to_setup_if_needed
  around_action :set_user_timezone

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
end
