class DashboardController < ApplicationController
  # GET /account
  def account
  end

  # PATCH /account
  def update_account
    if current_user.update(account_params)
      redirect_to url_for(controller: 'dashboard', action: 'account'),
                  notice: 'Dados atualizados com sucesso.'
    else
      render :account
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def account_params
      params.permit(:password, :password_confirmation)
    end
end
