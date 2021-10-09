# brew install poppler - install pdftohtml version 0.81.0 in your system (https://poppler.freedesktop.org/)
# gem install nokogiri axlsx
require 'nokogiri'
require 'axlsx'
require 'csv'

PDF_DIR = ARGV[0]

if PDF_DIR.to_s.size == 0
  puts "Exemplo de uso do script:"
  puts "ruby clear.rb diretorio/com/pdfs/de/notas/de/corretagem/da/clear/"
  exit
end

puts "Processando PDFs do diretório: #{PDF_DIR}"

class String
  def clean
    self.gsub(/\s+/, ' ').strip
  end
end

NOME_PAPEL = CSV.read("#{__dir__}/../db/seeds/empresas_b3.csv").map { |row| [row[3].to_s.upcase, row[0].gsub(/[0-9]+\Z/, '')] }.to_h
TIPO_NUMERO = {
  'ON'  => 3,
  'PN'  => 4,
  'UNT' => 11,
}

$operacoes = {}

def read_pdf_path(path)
  cmd = "pdftohtml -stdout -xml -i \"#{path}\" 2>&1"
  puts "Running command: #{cmd}"
  xml = `#{cmd}`
  Nokogiri::XML(xml).css('page').map do |page|
    h = page.attr('height').to_f
    w = page.attr('width').to_f
    page.css('[top][left]').map do |item|
      {
        'left'   => (100 * item.attr('left').to_f / w).round(2),
        'right'  => (100 * (item.attr('left').to_f + item.attr('width').to_f) / w).round(2),
        'top'    => (100 * item.attr('top').to_f / h).round(2),
        'bottom' => (100 * (item.attr('top').to_f + item.attr('height').to_f) / h).round(2),
        'value'  => item.text.clean,
        'raw'    => item.text,
      }
    end
  end
end

def close?(value1, value2, max=0.2)
  # max default is 0.2% distance. max interval: 0..100
  return false if value1.nil? || value2.nil?
  (value2 - value1).abs <= max
end

def node_below(page, label)
  node = page.find { |n| n['value'].to_s.match(label) }
  return '' if node.nil?
  page.find_all { |n| close?(node['left'], n['left'], 3) && n['top'] >= node['bottom'] }.sort_by { |n| n['top'] }.first
end

def split_after(page, label)
  page.find { |n| n['value'].to_s.match(label) }&.[]('value').to_s.split(label, 2).last.strip
end

def process_pdf_path(path)
  pages = read_pdf_path(path)

  data_operacao   = nil
  data_liquidacao = nil
  data_liquidacao_lista = pages.map { |page| split_after(page, /\AL.+quido para/i) }

  pages.each_with_index do |page, i|
    _data_operacao   = node_below(page, /\AData preg.+o/i)&.[]('value')
    _data_liquidacao = split_after(page, /\AL.+quido para/i)
    data_operacao    = _data_operacao if _data_operacao.to_s.match(/[0-9]/)
    data_liquidacao  = _data_liquidacao if _data_liquidacao.to_s.match(/[0-9]/)
    data_liquidacao  ||= data_liquidacao_lista[i..-1].find { |d| d.to_s.strip.size > 0 }

    data_operacao_date = Date.strptime(data_operacao, '%d/%m/%Y')

    node = page.find { |n| n['value'].match(/Tipo mercado/) }
    headers = page.find_all { |n| close?(node['top'], n['top'], 1) }.sort_by { |n| n['left'] }
    left_cv    = headers.find { |h| h['value'].match(/\AC\/V/i) }['left']
    left_prazo = headers.find { |h| h['value'].match(/\APrazo/i) }['left']
    left_obs   = headers.find { |h| h['value'].match(/\AObs/i) }['left']
    left_preco = headers.find { |h| h['value'].match(/\APre.o .+ Ajuste/i) }['left']

    page.each do |node|
      if node['value'].match(/1\-BOVESPA/i)
        row = page.find_all { |n| close?(node['top'], n['top'], 1) && n['left'] >= node['left'] }.sort_by { |n| n['left'] }
        tipo_mercado = row.find_all { |n| n['left'] < left_prazo }.last['value']
        empresa      = row.find_all { |n| n['left'] < left_obs }.last['raw']
        ativo = case tipo_mercado
                when /OPCAO/i
                  'OPCAO'
                when /VISTA|FRACION.RIO/i
                  empresa.match(/\AFII\s+/i) ? 'FII' : 'ACAO'
                else
                  ''
                end
        if ativo == 'FII'
          papel = empresa.split(/\s{2}\s+/)[1]
        else
          empresa, tipo = empresa.split(/\s{2}\s+/, 2)
          empresa = empresa.to_s.upcase.gsub(/\A\s*[0-9]{2}\/[0-9]{2}\s*/, '')
          if papel = NOME_PAPEL[empresa]
            papel += TIPO_NUMERO[tipo.split(/\s/).first.to_s.upcase].to_s
          else
            papel = empresa
          end
        end
        operacao = {}
        operacao['DATA OPERACAO']   = data_operacao
        operacao['DATA LIQUIDACAO'] = data_liquidacao
        operacao['ATIVO']           = ativo
        operacao['OPERACAO']        = row.find { |n| n['left'] >= left_cv }['value'][0].upcase == 'C' ? 'COMPRA' : 'VENDA'
        operacao['DAYTRADE?']       = 'N'
        operacao['QTD']             = row.find_all { |n| n['left'] < left_preco }.last['value'].gsub('.', '').to_i
        operacao['PRECO']           = row.find { |n| n['left'] >= left_preco }['value'].gsub('.', '').gsub(',', '.').to_f.round(2)
        $operacoes[data_operacao_date] ||= {}
        $operacoes[data_operacao_date][papel] ||= []
        $operacoes[data_operacao_date][papel] << operacao
      end
    end
  end
end

Dir.glob("#{PDF_DIR}/*.pdf").each { |path| process_pdf_path(path) }

# reduce operations by grouping with the same price
$operacoes.each do |data_operacao, operacoes_na_data|
  operacoes_na_data.each do |papel, ops|
    ops.each do |operacao|
      next if operacao['_SHOULD_REMOVE']
      ops.each do |op|
        next if operacao.equal?(op)
        if operacao['DATA LIQUIDACAO'] == op['DATA LIQUIDACAO'] &&
           operacao['OPERACAO'] == op['OPERACAO'] &&
           operacao['PRECO'] == op['PRECO']
           operacao['QTD'] += op['QTD']
           op['_SHOULD_REMOVE'] = true
        end
      end
    end
    ops.delete_if { |operacao| operacao['_SHOULD_REMOVE'] }
  end
end

# find daytrades
$operacoes.keys.each do |data_operacao|
  operacoes_na_data = $operacoes[data_operacao]
  operacoes_na_data.keys.each do |papel|
    ops = operacoes_na_data[papel]
    compras = ops.find_all { |op| op['OPERACAO'] == 'COMPRA' }
    vendas  = ops.find_all { |op| op['OPERACAO'] == 'VENDA' }
    compra = compras.sum { |op| op['QTD'] }
    venda  = vendas.sum { |op| op['QTD'] }
    if compra > 0 && venda > 0
      preco_compra = compras.sum { |op| op['QTD'] * op['PRECO'] } / compra
      preco_venda  = vendas.sum { |op| op['QTD'] * op['PRECO'] } / venda
      operacao_proto = compras.first
      ops = []
      if compra > venda
        ops << operacao_proto.merge('OPERACAO' => 'COMPRA', 'QTD' => compra - venda, 'PRECO' => preco_compra, 'DAYTRADE?' => 'N')
        ops << operacao_proto.merge('OPERACAO' => 'COMPRA', 'QTD' => venda, 'PRECO' => preco_compra, 'DAYTRADE?' => 'S')
        ops << operacao_proto.merge('OPERACAO' => 'VENDA', 'QTD' => venda, 'PRECO' => preco_venda, 'DAYTRADE?' => 'S')
      else
        ops << operacao_proto.merge('OPERACAO' => 'VENDA', 'QTD' => venda - compra, 'PRECO' => preco_venda, 'DAYTRADE?' => 'N')
        ops << operacao_proto.merge('OPERACAO' => 'VENDA', 'QTD' => compra, 'PRECO' => preco_venda, 'DAYTRADE?' => 'S')
        ops << operacao_proto.merge('OPERACAO' => 'COMPRA', 'QTD' => compra, 'PRECO' => preco_compra, 'DAYTRADE?' => 'S')
      end
      operacoes_na_data[papel] = ops
    end
  end
end

rows = []
$operacoes.keys.sort.each do |data_operacao|
  operacoes_na_data = $operacoes[data_operacao]
  operacoes_na_data.each do |papel, ops|
    ops.each do |op|
      rows << [
        op['DATA OPERACAO'],
        op['DATA LIQUIDACAO'],
        op['ATIVO'],
        op['OPERACAO'],
        op['DAYTRADE?'],
        papel,
        op['QTD'],
        op['PRECO'],
      ]
    end
  end
end

package = Axlsx::Package.new
workbook = package.workbook
sheet = workbook.add_worksheet(:name => "Operações")

sheet.add_row([
  'DATA OPERACAO',
  'DATA LIQUIDACAO',
  'ATIVO',
  'OPERACAO',
  'DAYTRADE?',
  'PAPEL',
  'QTD',
  'PRECO',
])

rows.each { |row| sheet.add_row(row) }

sheet_path = "#{PDF_DIR}/_operacoes-#{Time.now.to_i}.xlsx"
package.serialize(sheet_path)

puts
puts "A planilha de operações foi gerada e salva em:"
puts sheet_path
