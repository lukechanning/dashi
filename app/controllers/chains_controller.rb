class ChainsController < ApplicationController
  before_action :set_chain, only: [ :show, :destroy ]

  def index
    @chains = current_user.chains.order(created_at: :desc)
  end

  def show
    @chain_items = @chain.chain_items
  end

  # Intentionally JSON-only: called exclusively by the creation wizard via fetch.
  def create
    @chain = current_user.chains.build(chain_params)

    if @chain.save
      activate_first_item
      render json: { id: @chain.id, redirect: root_path }, status: :created
    else
      render json: { errors: @chain.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @chain.destroy
    redirect_to root_path, notice: "Chain deleted."
  end

  private

  def set_chain
    @chain = current_user.chains.find(params[:id])
  end

  def chain_params
    params.require(:chain).permit(
      :title, :description, :emoji,
      chain_items_attributes: [ :title, :description, :emoji, :item_type, :position ]
    )
  end

  def activate_first_item
    first = @chain.chain_items.first
    return unless first

    # Use the due_date from the first item param if provided, else today
    due_date_str = params.dig(:chain, :chain_items_attributes, 0, :due_date).presence
    due_date = if due_date_str
      begin
        Date.parse(due_date_str)
      rescue ArgumentError
        Date.current
      end
    else
      Date.current
    end

    ChainItems::ActivateService.new(first, due_date: due_date).call
  end
end
