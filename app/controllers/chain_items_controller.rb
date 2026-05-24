class ChainItemsController < ApplicationController
  before_action :set_chain
  before_action :set_chain_item

  def activate
    due_date_str = params.require(:due_date)
    due_date = begin
      Date.parse(due_date_str)
    rescue ArgumentError
      return render json: { errors: [ "due_date is not a valid date" ] }, status: :unprocessable_entity
    end

    result = ChainItems::ActivateService.new(@chain_item, due_date: due_date).call

    if result.success?
      render json: { todo_id: result.todo&.id }
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_chain
    @chain = current_user.chains.find(params[:chain_id])
  end

  def set_chain_item
    @chain_item = @chain.chain_items.find(params[:id])
  end
end
