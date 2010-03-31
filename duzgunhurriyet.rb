require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'nokogiri'
require 'erb'
require 'logger'
require 'cgi'
require 'iconv'

class Manset < Struct.new(:img, :text, :link); end
class Kose < Struct.new(:yazar, :baslik, :text); end

def siktiret url
  url =~ /(magazin|galeri|spor|webtv)/
end

def mansetler
  url = 'http://www.hurriyet.com.tr/anasayfa/'
  logger.info("Fetching #{url}")
  doc = Nokogiri::HTML(open(url))
  logger.info("Fetched #{url}")
  links = Array.new
  biglinks = Array.new

  doc.css(".hurriyet2010_uclumanset1").each do |e|
    img = e.children.css('img')[0]['src']
    link = e.children.css('a')[0]['href']
    links << Manset.new(img,nil,link) unless siktiret(link)
  end
  
  1.upto(4) do |i|
    div = doc.css("#hurriyet_4lu_#{i}")
    img = div.css('img')[0]['src']
    link = div.css('a')[0]['href']
    links << Manset.new(img, nil, link) unless siktiret(link)
  end

  doc.css(".mansetImageDiv").each do |e|
    img = e.children.css('img')[0]['src']
    link = e.children.css('a')[0]['href']
    biglinks << Manset.new(img,nil,link) unless siktiret(link)
  end

  [links, biglinks]
end

def scrape_haber url
  logger.info("Fetching #{url}")
  doc = Nokogiri::HTML(open(url))
  logger.info("Fetched #{url}")
  
  title = doc.css("h1")[0].inner_text

  toplevel = doc.css(".hurriyet2008_detail_text")[0].children
  toplevel.delete(toplevel[1])
  res = []

  toplevel.each do |elm|
    case elm
    when Nokogiri::XML::Text
      res << elm unless elm.inner_text.strip.empty?
    when Nokogiri::XML::Element
      res << elm if elm.name == "strong"
      
      if elm.name == "div"
        elm.children.each do |e|
          case e
          when Nokogiri::XML::Text
            res << e unless e.inner_text.strip.empty?
          when Nokogiri::XML::Element
            res << e unless e.name == "br" || e.name == "table"
          end
        end
      end
    end
  end

  [title, res.map{|x| x.to_html}.join("")]
end

if production?
  LOGGER = Logger.new("log/production.log")
elsif development?
  LOGGER = Logger.new("log/development.log")
end

def logger; LOGGER; end

def max_age(age)
  if production?
    headers 'Cache-Control' => "max-age=#{age}"
  else
    headers 'Cache-Control' => "no-cache"
  end
end

set :views, File.dirname(__FILE__)

get '/' do
  max_age 300

  @sur, @mansetler = mansetler
  erb :index
end

get %r{/haber/(.+)} do
  max_age 1800

  @url = CGI.unescape(params[:captures][0])
  @title, @html = scrape_haber @url
  @html = Iconv.conv("UTF-8", "Windows-1254", @html)
  erb :haber
end

