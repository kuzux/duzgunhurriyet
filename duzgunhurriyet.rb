require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'nokogiri'
require 'erb'
require 'logger'

class Manset < Struct.new(:img, :text, :link); end
class Kose < Struct.new(:yazar, :baslik, :text); end

def mansetler
  url = 'http://www.hurriyet.com.tr/anasayfa/'
  logger.info("Fetching #{url}")
  doc = Nokogiri::HTML(open(url))
  logger.info("Fetched #{url}")
  links = []
  doc.xpath("/html/body/table/tr[2]/td/table/tr/td/table/tr/td/a").each do |elm|
    img = elm.children.first
    links << Manset.new(img['longdesc'],img['alt'],elm['href'])
  end
  1.upto(10) do |i|
    elm = doc.css("div#hurmanset#{i} a").first
    img = elm.children.first
    links << Manset.new(img['longdesc'],img['alt'],elm['href'])
  end
  links
end

if production?
  LOGGER = Logger.new("log/production.log")
elsif development?
  LOGGER = Logger.new("log/development.log")
end

def logger; LOGGER; end

set :views, File.dirname(__FILE__)

get '/' do
  headers 'Cache-Control' => "max-age=300"
  @mansetler = mansetler
  erb :index
end

