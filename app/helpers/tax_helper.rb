module TaxHelper
  def aliquot_label(aliquot)
    case aliquot
    when 0.15
      'normais'
    when 0.20
      'daytrade'
    else
      "com alíquota #{number_to_percentage 100 * aliquot}"
    end
  end
end
