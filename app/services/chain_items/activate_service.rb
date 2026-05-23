module ChainItems
  class ActivateService
    Result = Struct.new(:success?, :todo, :project, :errors)

    def initialize(chain_item, due_date:)
      @chain_item = chain_item
      @due_date = due_date
      @user = chain_item.chain.user
    end

    def call
      return failure("Already activated") if @chain_item.activated?

      ActiveRecord::Base.transaction do
        if @chain_item.item_type == "todo"
          activate_as_todo
        else
          activate_as_project
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def activate_as_todo
      todo = @user.todos.create!(
        title: @chain_item.title,
        due_date: @due_date
      )
      @chain_item.update!(todo_id: todo.id)
      Result.new(true, todo, nil, [])
    end

    def activate_as_project
      project = @user.projects.create!(
        title: @chain_item.title,
        description: @chain_item.description,
        emoji: @chain_item.emoji
      )
      @chain_item.update!(project_id: project.id)
      Result.new(true, nil, project, [])
    end

    def failure(message)
      Result.new(false, nil, nil, [ message ])
    end
  end
end
