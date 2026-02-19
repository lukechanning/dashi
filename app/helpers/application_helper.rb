module ApplicationHelper
  AVATAR_COLORS = %w[
    bg-violet-500 bg-pink-500 bg-blue-500 bg-emerald-500
    bg-amber-500 bg-rose-500 bg-cyan-500 bg-purple-500
  ].freeze

  def user_initials(user)
    user.name.split.map(&:first).first(2).join.upcase
  end

  def user_avatar_color(user)
    AVATAR_COLORS[user.id % AVATAR_COLORS.length]
  end

  def user_avatar(user, size: :md, border: false)
    size_classes = {
      xs: "w-5 h-5 text-xs",
      sm: "w-6 h-6 text-xs",
      md: "w-8 h-8 text-sm",
      lg: "w-10 h-10 text-base"
    }
    border_class = border ? "border-2 border-white" : ""
    content_tag(
      :div, user_initials(user),
      class: "#{size_classes[size]} rounded-full flex items-center justify-center " \
             "font-semibold text-white #{user_avatar_color(user)} #{border_class} flex-shrink-0",
      title: user.name
    )
  end

  def avatar_stack(users, size: :sm, max: 3)
    shown = users.first(max)
    overflow = users.size - max
    content_tag(:div, class: "flex -space-x-1.5 items-center") do
      parts = shown.map { |u| user_avatar(u, size: size, border: true) }
      if overflow > 0
        parts << content_tag(
          :div, "+#{overflow}",
          class: "w-6 h-6 rounded-full bg-stone-200 text-stone-600 text-xs " \
                 "flex items-center justify-center font-medium border-2 border-white"
        )
      end
      safe_join(parts)
    end
  end
end
