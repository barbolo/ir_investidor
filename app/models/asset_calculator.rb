class AssetCalculator
  TAX_ALIQUOT = {
    'common'   => BigDecimal('0.15'),
    'daytrade' => BigDecimal('0.20'),
    'fii'      => BigDecimal('0.20'),
  }

  IRRF_ALIQUOT = {
    'common'   => BigDecimal('0.15'),
    'daytrade' => BigDecimal('0.20'),
  }

  attr_accessor :session, :logs, :assets, :tax

  def initialize(session)
    self.session   = session
    self.logs      = []
    self.assets    = Asset::TYPE.values.map { |asset_class| [asset_class, {}] }.to_h
    self.tax       = TaxCalculator.new(session, self)
  end

  def calculate_and_save
    last_order_year = nil
    session.orders.order(:ordered_at).order_by_type.each do |order|
      if last_order_year && last_order_year != order.ordered_at.year
        save_assets_at_end_of_year(last_order_year, order.ordered_at.year - 1)
      end
      last_order_year = order.ordered_at.year
      case order.order_type
      when Order::TYPE['compra']
        compra(order)
      when Order::TYPE['venda']
        venda(order)
      when Order::TYPE['conversao']
        conversao(order)
      when Order::TYPE['compensacao']
        compensacao(order)
      when Order::TYPE['isencao']
        isencao(order)
      when Order::TYPE['semisencao']
        semisencao(order)
      end
    end
    save_assets_at_end_of_year(last_order_year, Date.today.year)
    save_assets
    tax.calculate_and_save
    save_logs
  end

  def save_assets_at_end_of_year(year_first, year_last)
    (year_first..year_last).each do |year|
      AssetsEndOfYear.create!(session_id: session.id, year: year, assets: assets)
    end
  end

  def save_assets
    assets.each do |asset_class, asset_class_assets|
      asset_class_assets.each do |asset_name, asset_values|
        next if asset_values['quantity'] == 0
        asset = Asset.create(
          session_id:     session.id,
          asset_class:    asset_class,
          name:           asset_name,
          quantity:       asset_values['quantity'],
          price:          asset_values['price'],
          current_price:  asset_values['price'],
          value:          asset_values['price'] * asset_values['quantity'],
          current_value:  asset_values['price'] * asset_values['quantity'],
          profit:         0,
          last_order_at:  asset_values['last_order_at'],
        )
        if asset.errors.any?
          logs << "Falha ao salvar posição em ativo. #{asset.errors.full_messages.join(', ')}"
        end
      end
    end
  end

  def save_logs
    (logs + tax.logs).sort.uniq.each do |log|
      SessionLog.create!(session_id: session.id, message: log)
    end
  end

  def compra(order)
    asset = asset_for(order)

    if asset['quantity'] >= 0
      # increase long allocation
      asset['price']          = (asset['quantity'] * asset['price'] + order.quantity * order.price_considering_costs) / (asset['quantity'] + order.quantity)
      asset['quantity']       += order.quantity

    elsif order.quantity <= asset['quantity'].abs
      # reduce short allocation
      tax.add_entry(order, asset)
      asset['quantity']       += order.quantity

    else
      # from short to long
      tax.add_entry(order, asset)
      asset['quantity']       += order.quantity
      asset['price']          = order.price_considering_costs
    end

    asset['last_order_at']    = order.ordered_at

    tax.add_trade(order)
  end

  def venda(order)
    asset = asset_for(order)
    tax.tax_for(order, asset)[0]['sales'] += (order.quantity * order.price)

    if asset['quantity'] <= 0
      # increase short allocation
      asset['price']          = (asset['quantity'].abs * asset['price'] + order.quantity * order.price_considering_costs) / (asset['quantity'].abs + order.quantity)
      asset['quantity']       -= order.quantity

    elsif order.quantity <= asset['quantity']
      # reduce long allocation
      tax.add_entry(order, asset)
      asset['quantity']       -= order.quantity

    else
      # from long to short
      tax.add_entry(order, asset)
      asset['quantity']       -= order.quantity
      asset['price']          = order.price_considering_costs
    end

    asset['last_order_at']    = order.ordered_at

    tax.add_trade(order)
  end

  def conversao(order)
    asset = asset_for('asset_class' => order.asset_class, 'name' => order.name)
    return if asset['quantity'] == 0

    # calculate price and quantity after conversion
    ratio    = order.new_quantity / order.old_quantity
    price    = asset['price'] / ratio
    quantity = (asset['quantity'] * ratio).to_i

    # reset (get rid of) the old asset
    asset['quantity'] = 0
    asset['price']    = 0

    # update the new asset (the one after conversion)
    new_asset = asset_for('asset_class' => order.asset_class, 'name' => order.new_name)
    new_asset['price']         = (new_asset['quantity']*new_asset['price'] + quantity * price)/(new_asset['quantity'] + quantity)
    new_asset['quantity']      += quantity
    new_asset['last_order_at'] = [asset['last_order_at'], new_asset['last_order_at']].max
  end

  def compensacao(order)
    tax.compensacoes[order.ordered_at.beginning_of_month] = {
      'common'          => order.accumulated_common,
      'daytrade'        => order.accumulated_daytrade,
      'fii'             => order.accumulated_fii,
      'irrf_common'     => order.accumulated_irrf, # consider IRRF for common
      'irrf_daytrade'   => 0,
      'irrf_fii'        => 0,
    }
  end

  def isencao(order)
    tax.isencoes["#{order.asset_class}-#{order.name}"] = true
  end

  def semisencao(order)
    tax.isencoes.delete("#{order.asset_class}-#{order.name}")
  end

  private
    def asset_for(options)
      asset_class = options['asset_class'] || options['order'].try(:asset_class)
      order_name = options['name'] || options['order'].try(:name)
      assets[asset_class][order_name] ||= {
        'quantity'      => 0,
        'price'         => 0,
        'last_order_at' => Date.new(1890, 8, 23)
      }
    end
end
