module HoldingsHelper
  def holdings_value_for_asset(asset)
    return @holdings_values[asset] if @holdings_values.present?
    @holdings_values = { 'Total' => BigDecimal.new(0) }
    Transaction::ASSET.values.each do |asset|
      @holdings_values[asset] = BigDecimal.new(0)
    end
    @holdings.each do |h|
      @holdings_values[h.asset] += h.current_value
      @holdings_values['Total'] += h.current_value
    end
    holdings_value_for_asset(asset)
  end
end
