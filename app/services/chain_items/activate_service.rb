module ChainItems
  class ActivateService
    Result = Struct.new(:success?, :todo, :errors)

    def initialize(chain_item, due_date:)
      @chain_item = chain_item
      @due_date = due_date
      @user = chain_item.chain.user
    end

    def call
      return failure("Already activated") if @chain_item.activated?

      ActiveRecord::Base.transaction do
        todo = @user.todos.create!(
          title: @chain_item.title,
          due_date: @due_date,
          project_id: @chain_item.target_project_id
        )
        @chain_item.update!(todo_id: todo.id)
        Result.new(true, todo, [])
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def failure(message)
      Result.new(false, nil, [ message ])
    end
  end
end
