class TransactionsController < ApplicationController
  before_action :set_transaction, only: [:edit, :update, :destroy]
  before_action :parse_form, only: [:create, :update]

  # GET /transactions
  def index
    @transactions = current_user.transactions.includes(:user_broker, :book).all
  end

  # GET /transactions/new
  def new
    @transaction = current_user.transactions.build
    @transaction.user_broker_id ||= session[:last_used_user_broker_id]
    @transaction.book_id ||= session[:last_used_book_id]
  end

  # GET /transactions/1/edit
  def edit
    @can_submit = true
  end

  # POST /transactions
  def create
    @transaction = current_user.transactions.build(transaction_params)

    if params[:do_submit].present? && @transaction.save
      redirect_to edit_transaction_path(@transaction), notice: 'Operação criada com sucesso.'
    else
      if transaction_params.has_key?(:book_id) && @transaction.valid?
        @can_submit = true
      end
      render :new
    end
  end

  # PATCH/PUT /transactions/1
  def update
    if @transaction.update(transaction_params)
      redirect_to edit_transaction_path(@transaction), notice: 'Operação atualizada com sucesso.'
    else
      render :edit
    end
  end

  # DELETE /transactions/1
  def destroy
    @transaction.destroy
    redirect_to transactions_url, notice: 'Operação removida com sucesso.'
  end

  private
    def parse_form
      parse_dates(params[:transaction], :operation_at, :settlement_at,
                  :expire_at)
      parse_decimals(params[:transaction], :price, :irrf)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = current_user.transactions.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def transaction_params
      t_params = params.fetch(:transaction).permit(:user_broker_id, :asset,
        :operation, :book_id, :ticker, :name, :quantity, :price, :operation_at,
        :settlement_at, :irrf, :costs_breakdown)
      t_params = t_params.to_unsafe_h

      if (cb = params[:transaction][:costs_breakdown]).present?
        cb_new = t_params[:costs_breakdown] = {}
        cb[:keys].each_with_index do |key, i|
          val = BigDecimal.new(cb[:values][i].to_s.gsub('.', '').gsub(',', '.'))
          cb_new[key] = val
        end
      end
      t_params
    end
end
