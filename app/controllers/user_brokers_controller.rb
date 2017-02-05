class UserBrokersController < ApplicationController
  before_action :set_user_broker, only: [:show, :edit, :update, :destroy]

  # GET /user_brokers
  def index
    @user_brokers = current_user.user_brokers.includes(:broker).all
  end

  # GET /user_brokers/new
  def new
    @user_broker = current_user.user_brokers.build
  end

  # GET /user_brokers/1/edit
  def edit
  end

  # POST /user_brokers
  def create
    @user_broker = current_user.user_brokers.build(user_broker_params)

    if @user_broker.save
      redirect_to user_brokers_path, notice: 'Conta em corretora criada com sucesso.'
    else
      render :new
    end
  end

  # PATCH/PUT /user_brokers/1
  def update
    if @user_broker.update(user_broker_params)
      redirect_to user_brokers_path, notice: 'Conta em corretora atualizada com sucesso.'
    else
      render :edit
    end
  end

  # DELETE /user_brokers/1
  def destroy
    @user_broker.destroy
    redirect_to user_brokers_url, notice: 'Conta em corretora removida com sucesso.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user_broker
      @user_broker = current_user.user_brokers.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def user_broker_params
      params.fetch(:user_broker).permit(:broker_id, :name)
    end
end
