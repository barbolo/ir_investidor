require 'fileutils'
require 'csv'
require 'mechanize'

THREADS = 5

DB_DIR = "#{__dir__}/../db/seeds"
FileUtils.mkdir_p DB_DIR

CSV_PATH = "#{DB_DIR}/empresas_b3.csv"
FileUtils.touch CSV_PATH

VISITED_LINKS_PATH = "#{__dir__}/../tmp/visited_links_empresas_b3.txt"
FileUtils.touch VISITED_LINKS_PATH

$visited_links = File.read(VISITED_LINKS_PATH).split("\n").map { |l| [l, true] }.to_h
$rows = CSV.read(CSV_PATH)

thread_csv_write = Thread.new do
  # write CSV and visited links every 10 seconds
  while true
    CSV.open(CSV_PATH, 'w') { |csv| $rows.uniq.sort.each { |row| csv << row } }
    File.open(VISITED_LINKS_PATH, 'w') { |f| f.write $visited_links.keys.join("\n") }
    sleep 10
  end
end

queue = Queue.new

def new_agent
  agent             = Mechanize.new
  agent.user_agent  = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36'
  agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
  agent.max_history = 3
  agent
end

def download(link)
  agent = new_agent()
  begin
    agent.get link
    razao_social = agent.page.parser.css('h2').first.text.strip
    agent.get agent.page.parser.css('#ctl00_contentPlaceHolderConteudo_iframeCarregadorPaginaExterna').first.attr('src')
    dados = agent.page.parser.css('#accordionDados').first
    codigos     = dados.css('.LinkCodNeg').map { |a| a.text.strip }.uniq.find_all { |l| l.to_s.size > 0 }
    cnpj        = dados.css('td:contains("CNPJ:"):not(:has(td))').first.next_element.text.strip.gsub(/[^0-9]/, '')
    nome_pregao = dados.css('td:contains("Nome de Pregão:"):not(:has(td))').first.next_element.text.strip
    codigos.each do |codigo|
      $rows << [codigo, cnpj, razao_social, nome_pregao]
    end
    $visited_links[link] = true
    puts "Visited #{link}"
  ensure
    agent.shutdown
  end
end

agent = new_agent()

agent.get 'http://bvmf.bmfbovespa.com.br/cias-listadas/empresas-listadas/BuscaEmpresaListada.aspx?idioma=pt-br'
form = agent.page.form_with(id: 'aspnetForm')

btn = agent.page.parser.css('input[value="Todas"]').first
onclick = btn.attr('onclick')
form['__EVENTTARGET'] = btn.attr('name').gsub('$', ':')
form[form.fields.find { |f| f.name.to_s.match(/PostDataValue/) }.name] = "#{onclick[/([^']+)\'\, event/, 1]},ActiveElement,#{btn.attr('id')};"
form[form.fields.find { |f| f.name.to_s.match(/tabMenuEmpresaListada/) }.name] = '{"State":{},"TabState":{"ctl00_contentPlaceHolderConteudo_tabMenuEmpresaListada_tabNome":{"Selected":true}}}'
form['RadAJAXControlID'] = 'ctl00_contentPlaceHolderConteudo_AjaxPanelBusca'
form['httprequest'] = 'true'
form.submit

links = Nokogiri::HTML(agent.page.body).css('.MasterTable_SiteBmfBovespa a').map { |a| agent.resolve(a.attr('href')).to_s }.uniq

agent.shutdown

links.each { |link| queue << link }
THREADS.times { queue << 'END' }

THREADS.times.map do
  Thread.new do
    while (link = queue.pop) != 'END'
      next if $visited_links[link]
      begin
        download(link)
      rescue Exception => e
        puts "Exception with link #{link}"
        puts e
        puts e.backtrace&.join("\n")
      end
    end
  end
end.each &:join


thread_csv_write.kill
CSV.open(CSV_PATH, 'w') { |csv| $rows.uniq.sort.each { |row| csv << row } }
File.open(VISITED_LINKS_PATH, 'w') { |f| f.write $visited_links.keys.join("\n") }
