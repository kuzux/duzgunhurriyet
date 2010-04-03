require 'rubygems'
require 'sinatra'
require 'logger'
require 'erb'
require 'cgi'
require 'iconv'
require 'scrape'

class Manset < Struct.new(:img, :text, :link); end

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

  @sur, @mansetler = Scrape.mansetler
  erb :index
end

get %r{/haber/(.+)} do
  max_age 1800

  @url = CGI.unescape(params[:captures][0])
  @title, @html = Scrape.haber @url
  @html = Iconv.conv("UTF-8", "Windows-1254", @html)
  erb :haber
end

