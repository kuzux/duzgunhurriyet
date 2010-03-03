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

  doc.css(".hurriyet2010_uclumanset1").each do |e|
    img = e.children.css('img')[0]['src']
    link = e.children.css('a')[0]['href']
    links << Manset.new(img,nil,link)
  end
  
  1.upto(4) do |i|
    div = doc.css("#hurriyet_4lu_#{i}")
    img = div.css('img')[0]['src']
    link = div.css('a')[0]['href']
    links << Manset.new(img, nil, link)
  end

  doc.css(".mansetImageDiv").each do |e|
    img = e.children.css('img')[0]['src']
    link = e.children.css('a')[0]['href']
    links << Manset.new(img,nil,link)
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

