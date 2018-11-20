require 'httparty'
require 'nokogiri'
require 'byebug'
require 'time'
require 'mail'

def scraper
  url = "https://www.nic.cl/registry/Whois.do?d=#{@domain}"
  table = search(url, '.tablabusqueda')
  data = {}
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

def notify?(data)
  Time.parse(data['expiration_at']) < Time.now
end

def sendmail(message)
  mail = Mail.new do
    from     ''
    to       ''
    subject  'Dominio liberado :)'
    body     message
  end
  mail.delivery_method :sendmail

  mail.deliver
end

def available?(data)
  Time.parse(data['expiration_at']) != Time.parse(@expiration_at)
end

@domain = ARGV[0]
@expiration_at = ARGV[1]

return if @domain.nil? || @expiration_at.nil?

data = scraper

p Time.now
p data

if available?(data)
  message = "Nos cagaron con #{@domain} :("
  sendmail(message)
end

if notify?(data)
  message = "Al fin #{@domain} está disponible :)"
  sendmail(message)
end
