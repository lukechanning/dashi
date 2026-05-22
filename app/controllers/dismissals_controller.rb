class DismissalsController < ApplicationController
  ALLOWED_BANNERS = %w[reflection stale].freeze

  def create
    banner = params[:banner].to_s
    return head :unprocessable_entity unless banner.in?(ALLOWED_BANNERS)

    cookies.signed[:"#{banner}_dismissed_on"] = {
      value:     Date.current.to_s,
      expires:   Date.current.end_of_day,
      httponly:  true,
      same_site: :lax
    }
    head :no_content
  end
end
