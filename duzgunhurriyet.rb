require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'nokogiri'
require 'erb'

class Manset < Struct.new(:img, :text, :link); end

def screenscrape
  doc = Nokogiri::HTML(open('http://www.hurriyet.com.tr/anasayfa/'))
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

set :views, File.dirname(__FILE__)

get '/' do
  @mansetler = screenscrape
  erb :index
end

