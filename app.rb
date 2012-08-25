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
#node = stats.find(:api => params[:api_key]).first
#  if node 
#    node[:country][c.country_code2] ||= 0
#    node[:country][c.country_code2] += 1    
#    stats.update({ :_id => note[:_id] }, note) 
#  else 
#    node = {
#      :api => params[:api_key],
#      :country => {c.country_code2 => 1}
#    }
#    stats.insert(node)  
#  end
#summary
#db.visitors.update({api: 'axcoto'}, {$inc: {vn: 1}}, true);
  hits = db.collection('hits');
  hits.insert({
    :api => params[:api_key],
    :ip => request.ip, 
    :time => {:hour => now.hour, :min => now.min, :sec => now.sec}, 
    :country => {:code2 => c.country_code2, :name => c.country_name} 
  })

  stats = db.collection('summaries'); 
  stats.update({:api => params[:api_key]}, {:$inc => {c.country_code2 => 1}}, {:upsert => true})  
  node = stats.find(:api => params[:api_key]).first
  node.delete_if {|k,v| k=='api' || k=='_id'}
  total_hit = 0; 
  node.each { |k, v| total_hit += v }
  
  # node.each do |country, hit|
  #   node[country] = {
  #     :hit => hit, :percent => (hit.to_f / total_hit.to_f * 100).round(0)
  #   }
  # end

  node.each do |country, hit| 
  end
  chart_url = "http://chart.apis.google.com/chart?chs=300x225&cht=p&chds=a&chdl=#{node.keys.join('|')}&chd=t:#{node.values.join(',')}"
  #haml :hit, :layout => false, :locals => {:c => c, :api => params[:api_key], :stats => node}
end


get '/css/:style.css' do
	less params[:style].to_sym, :paths => ["public/css"], :layout => false
end

get '/help' do
  "@Help Page"
end
