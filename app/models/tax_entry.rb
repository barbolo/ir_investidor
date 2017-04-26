class TaxEntry < ApplicationRecord
  belongs_to :tax

  def asset_class_name
    code = Transaction::ASSET_REVERSED[asset]
    I18n.t code, scope: 'constants.asset'
  end
end
