class Seeds::Brokers
  def self.all
    path = "#{Rails.root}/db/data/brokers.csv"
    if !File.exists?(path)
      # if CSV doesn't exist, create one
      links = brokers_links
      brokers = links.map { |link| broker(link) }
      CSV.open(path, 'wb') do |csv|
        brokers.each do |broker|
          csv << [broker[:cnpj], broker[:name]]
        end
      end
    end
    CSV.read(path, 'rb')
  end

  def self.brokers_links
    links = []
    url = 'http://www.bmfbovespa.com.br/pt_br/servicos/participantes/busca-de-corretoras/'
    agent = Mechanize.new
    agent.get url
    while true
      puts 'downloading brokers links'
      begin
        doc = agent.page.parser
        links += doc.css('h6 a').map { |a| url + a.attr(:href).gsub(/\A\.\//, '') }
        arrow = doc.css('ul.pagination .arrow:last').first
        break if arrow.attr(:class).index('unavailable') # last page
        href = arrow.css('a').first.attr('href')
        form = agent.page.form_with id: href[/document\.forms\['([^']+)/, 1]
        form['pagination'] = href[/y\.value='([^']+)/, 1]
        destid = href[/onSubmitForm\('([^']+)','([^']+)/, 2]
        action = CGI.escapeHTML('main' + form.action.split('/main').last)
        parameters = %(<parameters destId="#{destid}" destType="lumII"><p n="lumFormAction">http://www.bmfbovespa.com.br/#{action}</p><p n="doui_fromForm">#{form['doui_fromForm']}</p><p n="lumII">#{destid}</p><p n="pagination">#{form['pagination']}</p><p n="bvmf-locales-content">pt_BR,en_US,es</p></parameters>)
        submit_form = agent.page.form_with id: 'LumisPortalForm'
        submit_form['lumNewParams'] = parameters
        submit_form['lumII'] = destid
        submit_form.submit
      rescue Exception => exc
        puts "Exception: #{exc}"
        puts 'Retrying'
        retry
      end
    end
    links.uniq
  end

  def self.broker(broker_link)
    puts 'Downloading broker'
    puts broker_link
    doc = Mechanize.new.get(broker_link).parser
    name = doc.css('h2').text.clean
    cnpj = doc.css('h3').text.gsub(/[^0-9]/, '')
    {name: name, cnpj: cnpj}
  rescue Exception => exc
    puts "Exception: #{exc}"
    puts 'Retrying'
    retry
  end
end
