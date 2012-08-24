# encoding: utf-8
require 'sinatra'
require 'mongo'
require 'json'
require 'haml'
require 'net/http'
require 'uri'
require 'open-uri'
require 'less'
require 'rest-client'
require 'geoip'
require 'date'

def get_connection
  return @db if @db
  if ENV['MONGOLAB_URI']
    #mongodb://heroku_app6870207:jc09imprmq9qks1nru81cvqsh3@ds029827-b.mongolab.com:29827/heroku_app6870207
    uri = ENV['MONGOLAB_URI']
  else
    uri = "mongodb://localhost:27017/visitors"
  end

  puri  = URI.parse(uri)
  conn = Mongo::Connection.from_uri(uri)
  @db   = conn.db(puri.path.gsub(/^\//, ''))
end


configure do
	set :logging, :true
	set :CLIENT_ID => 'd00b37e0fbf1488e8d49', :CLIENT_SECRET => '971ba392a08327aaa02b598ac71bc9258c1314cd'
 
  # same as `set :option, true`
  enable :option

  # same as `set :option, false`
  disable :option	
	
  # you can also have dynamic settings with blocks
  set(:css_dir) { File.join(views, 'css') }
	enable :sessions  
  
  #Less.paths << settings.views

end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def nl2br(s)
    s.gsub(/\r?\n/, "<br />") 
  end
end

get '/' do		
	haml :index, :locals => {}
end

get '/:api_key/hit' do   
  db = get_connection
  now = DateTime.now
  c = GeoIP.new('GeoIP.dat').country(request.ip)
  
  hits = db.collection('hits');
  stats = db.collection('summaries');
  node = stats.find(:api => params[:api_key]).first
  if node 
    node[:country][c.country_code2] ||= 0
    node[:country][c.country_code2] += 1    
    stats.update({ :_id => note[:_id] }, note) 
  else 
    node = {
      :api => params[:api_key],
      :country => {c.country_code2 => 1}
    }
    stats.insert(node)  
  end
  hits.insert({
    :api => params[:api_key],
    :ip => request.ip, 
    :time => {:hour => now.hour, :min => now.min, :sec => now.sec}, 
    :country => {:code2 => c.country_code2, :name => c.country_name} 
  })
  haml :hit, :layout => false, :locals => {:c => c, :api => params[:api_key]}
end


get '/css/:style.css' do
	less params[:style].to_sym, :paths => ["public/css"], :layout => false
end

get '/help' do
  "@Help Page"
end