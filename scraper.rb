require 'httparty'
require 'nokogiri'
require 'byebug'
require 'time'
require 'mail'

def scraper(domain)
  url = "https://www.nic.cl/registry/Whois.do?d=#{domain}"
  table = search(url, '.tablabusqueda')
  data = { domain: domain }
  table.search('tr').each do |tr|
    divs = tr.search('td div')
    next if divs.count.zero?

    key = translate(divs[0].text.strip)
    data[key] = divs[1].text.strip
  end

  data
end

def translate(value)
  translate = {
    'Titular:' => 'owner',
    'Agente Registrador:' => 'agent_recorder',
    'Fecha de creación:' => 'created_at',
    'Fecha de expiración:' => 'expiration_at',
    'Servidor de Nombre:' => 'server_name'
  }

  translate[value]
end

def parse_page(url)
  unparsed_page = HTTParty.get(url)
  Nokogiri::HTML(unparsed_page)
end

def search(url, element)
  parse_page(url).css(element)
end

def notify(data)
  sendmail(data) if Time.parse(data['expiration_at']) < Time.now
end

def sendmail(data)
  mail = Mail.new do
    from     ''
    to       ''
    subject  'Dominio liberado :)'
    body     "Se ha liberado el dominio #{data[:domain]}"
  end
  mail.delivery_method :sendmail

  mail.deliver
end

domain = ARGV[0]
return if domain.nil?

data = scraper(domain)
p data
notify(data)
