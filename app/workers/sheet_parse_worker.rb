class SheetParseWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'sheet_parse', retry: true

  REQUIRED_HEADERS = {
    'ATIVO'                 => /\A\s*ativo\s*\Z/i,
    'OPERACAO'              => /\A\s*opera..o\s*\Z/i,
    'DAYTRADE?'             => /\A\s*daytrade\??\s*\Z/i,
    'PAPEL'                 => /\A\s*papel\s*\Z/i,
    'QTD'                   => /\A\s*(qtd|quantidade)\s*\Z/i,
    'PRECO'                 => /\A\s*pre.o\s*\Z/i,
    'CUSTOS'                => /\A\s*custos\s*\Z/i,
    'IRRF'                  => /\A\s*irrf\s*\Z/i,
    'DATA OPERACAO'         => /\A\s*data\s*(da|de|)\s*opera..o\s*\Z/i,
    'DATA LIQUIDACAO'       => /\A\s*data\s*(da|de|)\s*liquida..o\s*\Z/i,
    'NOVO PAPEL'            => /\A\s*novo\s*papel\s*\Z/i,
    'QTD ANTIGA'            => /\A\s*(qtd|quantidade)\s*antiga\s*\Z/i,
    'QTD NOVA'              => /\A\s*(qtd|quantidade)\s*nova\s*\Z/i,
    'COMUNS A COMPENSAR'    => /\A\s*(comum|comuns)\s*(a|)\s*compensar\s*\Z/i,
    'DAYTRADE A COMPENSAR'  => /\A\s*daytrade\s*(a|)\s*compensar\s*\Z/i,
    'FIIS A COMPENSAR'      => /\A\s*(fii|fiis)\s*(a|)\s*compensar\s*\Z/i,
    'IRRF A COMPENSAR'      => /\A\s*irrf\s*(a|)\s*compensar\s*\Z/i,
  }

  def perform(session_id)
    session = ActiveRecord::Base.connection_pool.with_connection do
      Session.where(id: session_id).take
    end
    return if session.nil?

    # read sheet from storage using Roo
    begin
      path = ActiveStorage::Blob.service.send(:path_for, session.sheet.key)
      sheet = Roo::Spreadsheet.open(path, extension: session.sheet.filename.extension).sheet(0)
    rescue
      return SessionUpdateWorker.perform_async(session_id, sheet_ready: false, error: 'Não foi possível abrir a planilha')
    end

    # parse sheet and create orders
    iterate_method = sheet.respond_to?(:each_row_streaming) ? :each_row_streaming : :each
    headers = nil
    row_index = 1
    sheet.send(iterate_method) do |row|
      if row_index == 1
        headers = learn_headers(row)
        if (missing = REQUIRED_HEADERS.keys - headers.keys).size > 0
          return SessionUpdateWorker.perform_async(session_id, sheet_ready: false, error: "Cabeçalhos não encontrados: #{missing.join(', ')}")
        else
          SessionUpdateWorker.perform_async(session_id, sheet_ready: true)
        end
      else
        OrderCreateWorker.perform_async(order_args(session_id, row_index, row, headers))
      end
      row_index += 1
    end

    # Set a counter to follow the progress of orders being processed
    Session.counter(session_id, 'orders_pending').incr(row_index - 2)

    # After a timeout of 2 minutes, we'll call a hook that should be
    # automatically called just after all orders from the sheet were created.
    OrderAfterCreateAllWorker.perform_in(2.minutes, session_id)
  end

  def learn_headers(row)
    headers = {}
    row.each_with_index do |col, index|
      col = col.to_s
      if header = REQUIRED_HEADERS.find { |k, v| v.match(col) }
        headers[header[0]] = index
      end
    end
    headers
  end

  def order_args(session_id, row_index, row, headers)
    {
      'session_id'            => session_id,
      'row'                   => row_index,
      'asset_class'           => parse_cell(row[headers['ATIVO']]).try(:upcase),
      'order_type'            => parse_cell(row[headers['OPERACAO']]).try(:upcase),
      'daytrade'              => parse_boolean(row[headers['DAYTRADE?']]),
      'name'                  => parse_cell(row[headers['PAPEL']]).try(:upcase),
      'quantity'              => parse_number(row[headers['QTD']]),
      'price'                 => parse_number(row[headers['PRECO']]),
      'costs'                 => parse_number(row[headers['CUSTOS']]),
      'irrf'                  => parse_number(row[headers['IRRF']]),
      'ordered_at'            => parse_cell(row[headers['DATA OPERACAO']]),
      'settlement_at'         => parse_cell(row[headers['DATA LIQUIDACAO']]),
      'new_name'              => parse_cell(row[headers['NOVO PAPEL']]).try(:upcase),
      'old_quantity'          => parse_number(row[headers['QTD ANTIGA']]),
      'new_quantity'          => parse_number(row[headers['QTD NOVA']]),
      'accumulated_common'    => parse_number(row[headers['COMUNS A COMPENSAR']]),
      'accumulated_daytrade'  => parse_number(row[headers['DAYTRADE A COMPENSAR']]),
      'accumulated_fii'       => parse_number(row[headers['FIIS A COMPENSAR']]),
      'accumulated_irrf'      => parse_number(row[headers['IRRF A COMPENSAR']]),
    }
  end

  def parse_cell(cell)
    return nil if cell.nil?
    case cell.class.to_s
    when /Roo\:\:Excelx/
      cell.value
    else
      cell.to_s
    end
  end

  def parse_number(cell)
    return nil if cell.nil?
    case cell.class.to_s
    when /Roo\:\:Excelx/
      cell.value
    else
      cell.to_s.gsub('.', '').gsub(',', '.').gsub(/[^0-9.]/, '')
    end
  end

  def parse_boolean(cell)
    return nil if cell.nil?
    case cell.class.to_s
    when /Roo\:\:Excelx/
      cell.value.to_s.upcase == 'S'
    else
      cell.to_s.upcase == 'S'
    end
  end
end
