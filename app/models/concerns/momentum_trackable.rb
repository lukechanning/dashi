module MomentumTrackable
  extend ActiveSupport::Concern

  MOMENTUM_WINDOW = 7.days

  def momentum
    return :new if todos.empty?
    count = todos.where(completed_at: MOMENTUM_WINDOW.ago..).count
    count >= 3 ? :hot : count >= 1 ? :warm : :cool
  end

  def momentum_label
    { hot: "Active", warm: "In progress", cool: "Gone quiet", new: "Just started" }[momentum]
  end
end
