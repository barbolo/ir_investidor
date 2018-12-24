class TaxesController < ApplicationController
  def show
    @period = Date.parse(params[:period])
    @taxes = {}
    @first_period = Date.today
    current_session.taxes.each do |tax|
      @first_period = [tax.period, @first_period].min
      @taxes[tax.period.year] ||= {}
      @taxes[tax.period.year][tax.period.month] = tax
    end
    @tax = @taxes[@period.year][@period.month]
  end
end
