class AssetCalculator
  attr_accessor :session, :assets

  def initialize(session)
    self.session = session
    self.assets = {
      Order::ASSET_CLASS['acao']       => {},
      Order::ASSET_CLASS['opcao']      => {},
      Order::ASSET_CLASS['fii']        => {},
      Order::ASSET_CLASS['subscricao'] => {},
    }
  end

  def calculate
    session.orders.order(:ordered_at).each do |order|
      case order.order_type
      when Order::TYPE['compra']
        compra(order)
      when Order::TYPE['venda']
        venda(order)
      when Order::TYPE['conversao']
        conversao(order)
      end
    end
    save_assets
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
          message = "Falha ao salvar posição em ativo. #{asset.errors.full_messages.join(', ')}"
          SessionLogCreateWorker.perform_async(session.id, message)
        end
      end
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
      asset['quantity']       += order.quantity

    else
      # from short to long
      asset['quantity']       += order.quantity
      asset['price']          = order.price_considering_costs
    end

    asset['last_order_at']    = order.ordered_at
  end

  def venda(order)
    asset = asset_for(order)

    if asset['quantity'] <= 0
      # increase short allocation
      asset['price']          = (asset['quantity'].abs * asset['price'] + order.quantity * order.price_considering_costs) / (asset['quantity'].abs + order.quantity)
      asset['quantity']       -= order.quantity

    elsif order.quantity <= asset['quantity']
      # reduce long allocation
      asset['quantity']       -= order.quantity

    else
      # from long to short
      asset['quantity']       -= order.quantity
      asset['price']          = order.price_considering_costs
    end

    asset['last_order_at']    = order.ordered_at
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
