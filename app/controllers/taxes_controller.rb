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

  def declaracao
    @year = params[:year].to_i
    @discriminacao = params[:discriminacao] || 'CORRETORA CLEAR. CNPJ 02.332.886/0011-78.'
    @assets = {}
    current = AssetsEndOfYear.where(session_id: current_session.id, year: @year).take&.assets || {}
    before  = AssetsEndOfYear.where(session_id: current_session.id, year: @year - 1).take&.assets || {}
    current.each do |asset_class, asset_class_values|
      asset_class_values.each do |asset_name, asset_values|
        next if asset_values['quantity'] == 0
        @assets[asset_class] ||= {}
        @assets[asset_class][asset_name] ||= {}
        @assets[asset_class][asset_name]['quantity'] = asset_values['quantity']
        @assets[asset_class][asset_name]['current']  = (asset_values['price'].to_f * asset_values['quantity']).round(2)
      end
    end
    before.each do |asset_class, asset_class_values|
      asset_class_values.each do |asset_name, asset_values|
        next if asset_values['quantity'] == 0
        @assets[asset_class] ||= {}
        @assets[asset_class][asset_name] ||= {}
        @assets[asset_class][asset_name]['quantity'] ||= 0
        @assets[asset_class][asset_name]['before']   = (asset_values['price'].to_f * asset_values['quantity']).round(2)
      end
    end
    @taxes = current_session.taxes.where(period: Date.new(@year, 1, 1)..Date.new(@year, 12, 31)).order(:period).to_a
  end
end
