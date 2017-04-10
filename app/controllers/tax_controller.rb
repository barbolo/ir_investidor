class TaxController < ApplicationController
  def index
    @date = params[:period].present? ? Date.parse(params[:period]) : Date.today
    @tax = current_user.tax_for(@date)
    @taxes = current_user.taxes_by_year_and_month
  end
end
