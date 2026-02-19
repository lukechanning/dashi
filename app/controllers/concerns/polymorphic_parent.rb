module PolymorphicParent
  private

  def find_parent(types)
    types.each do |type, association|
      if params[:"#{type}_id"]
        return current_user.send(association).find(params[:"#{type}_id"])
      end
    end
    nil
  end
end
