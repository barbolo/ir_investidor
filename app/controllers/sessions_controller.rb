class SessionsController < ApplicationController
  layout 'sessions'
  skip_before_action :authenticate!, only: [:new, :create]

  def show
    if current_session&.orders_ready
      redirect_to transactions_path(secret: params[:secret])
    end
  end

  def new
    @session = Session.new
  end

  def create
    @session = Session.new(session_params)
    if @session.save
      redirect_to session_path(@session.secret)
    else
      flash.now[:alert] = "Houve um problema ao processar a planilha. Tente novamente."
      render :new
    end
  end

  def destroy
    SessionExpireWorker.perform_async(current_session.id)
    redirect_to root_path, notice: "Sua sessão foi encerrada e os dados de suas operações removidos. Até breve!"
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def session_params
      params.require(:session).permit(:sheet)
    end
end
