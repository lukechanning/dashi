module HabitsHelper
  def frequency_label(frequency)
    { "daily" => "Every day", "weekdays" => "Weekdays (Mon-Fri)", "custom" => "Custom days" }[frequency]
  end
end
