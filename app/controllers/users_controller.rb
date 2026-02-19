class UsersController < ApplicationController
  def update_timezone
    tz = params[:timezone].to_s.strip
    if ActiveSupport::TimeZone.find_tzinfo(tz)
      current_user.update!(timezone: tz)
      head :ok
    else
      head :unprocessable_entity
    end
  rescue TZInfo::InvalidTimezoneIdentifier
    head :unprocessable_entity
  end
end
