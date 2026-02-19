class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :set_user_timezone

  private

  def set_user_timezone(&block)
    timezone = current_user&.timezone.presence || "UTC"
    Time.use_zone(timezone, &block)
  end
end
