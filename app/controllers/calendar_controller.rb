class CalendarController < ApplicationController
  def show
    if params[:month].present?
      begin
        @month = Date.parse("#{params[:month]}-01")
      rescue ArgumentError
        @month = Date.current.beginning_of_month
      end
    else
      @month = Date.current.beginning_of_month
    end

    @start_date = @month.beginning_of_month.beginning_of_week(:sunday)
    @end_date = @month.end_of_month.end_of_week(:sunday)

    @completed_counts = current_user.todos
      .where.not(completed_at: nil)
      .where(completed_at: @start_date.beginning_of_day..@end_date.end_of_day)
      .pluck(:completed_at)
      .group_by { |t| t.to_date }
      .transform_values(&:count)

    @prev_month = @month - 1.month
    @next_month = @month + 1.month
    @today = Date.current
  end
end
