class SheetParseWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'sheet_parse', retry: true

  REQUIRED_HEADERS = {
    'ATIVO'           => /\A\s*ativo\s*\Z/i,
    'OPERACAO'        => /\A\s*opera..o\s*\Z/i,
    'DAYTRADE?'       => /\A\s*daytrade\??\s*\Z/i,
    'PAPEL'           => /\A\s*papel\s*\Z/i,
    'QTD'             => /\A\s*(qtd|quantidade)\s*\Z/i,
    'PRECO'           => /\A\s*pre.o\s*\Z/i,
    'CUSTOS'          => /\A\s*custos\s*\Z/i,
    'IRRF'            => /\A\s*irrf\s*\Z/i,
    'DATA OPERACAO'   => /\A\s*data\s*(da|de|)\s*opera..o\s*\Z/i,
    'DATA LIQUIDACAO' => /\A\s*data\s*(da|de|)\s*liquida..o\s*\Z/i,
    'NOVO PAPEL'      => /\A\s*novo\s*papel\s*\Z/i,
    'QTD ANTIGA'      => /\A\s*(qtd|quantidade)\s*antiga\s*\Z/i,
    'QTD NOVA'        => /\A\s*(qtd|quantidade)\s*nova\s*\Z/i,
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
    headers = nil
    row_index = 1
    sheet.each do |row|
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
      'session_id'    => session_id,
      'row'           => row_index,
      'asset_class'   => (row[headers['ATIVO']].try(:upcase) if headers['ATIVO']),
      'order_type'    => (row[headers['OPERACAO']].try(:upcase) if headers['OPERACAO']),
      'daytrade'      => (row[headers['DAYTRADE?']].try(:upcase) == 'S' if headers['DAYTRADE?']),
      'name'          => (row[headers['PAPEL']].try(:upcase) if headers['PAPEL']),
      'quantity'      => (row[headers['QTD']] if headers['QTD']),
      'price'         => (row[headers['PRECO']] if headers['PRECO']),
      'costs'         => (row[headers['CUSTOS']] if headers['CUSTOS']),
      'irrf'          => (row[headers['IRRF']] if headers['IRRF']),
      'ordered_at'    => (row[headers['DATA OPERACAO']] if headers['DATA OPERACAO']),
      'settlement_at' => (row[headers['DATA LIQUIDACAO']] if headers['DATA LIQUIDACAO']),
      'new_name'      => (row[headers['NOVO PAPEL']].try(:upcase) if headers['NOVO PAPEL']),
      'old_quantity'  => (row[headers['QTD ANTIGA']] if headers['QTD ANTIGA']),
      'new_quantity'  => (row[headers['QTD NOVA']] if headers['QTD NOVA']),
    }
  end
end
