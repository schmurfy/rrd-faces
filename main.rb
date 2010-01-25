#!/usr/bin/env ruby

__DIR__ = File.expand_path(File.dirname(__FILE__))
require File.join(__DIR__, 'gems/environment')

# sinatra have to be required there or else
# "ruby visage.rb" does not work to run the app
require 'sinatra'

Bundler::require_env()

require 'lib/config_loader'
require 'config/config'

set :public, __DIR__ + '/public'
set :views,  __DIR__ + '/views'

template :layout do 
  File.read('views/layout.haml')
end

# infrastructure for embedding
# get '/javascripts/visage.js' do
#   javascript = ""
#   %w{raphael-min g.raphael g.line mootools-1.2.3-core mootools-1.2.3.1-more graph}.each do |js|
#     javascript += File.read(File.join(__DIR__, 'public', 'javascripts', "#{js}.js"))
#   end
#   javascript
# end


get '/' do 
  @hosts = GraphDrawer::view.machines.keys
  haml :index
end

get '/:host' do 
  if GraphDrawer::view.machines[params[:host].to_sym]
    @hosts = GraphDrawer::view.machines.keys
  
    @graphs = GraphDrawer::view.default.values
    @graphs << GraphDrawer::view.machines[params[:host].to_sym].values
    @graphs.flatten!
  
    haml :index
  end
end

get '/data/:host/:view' do
  content_type :json
  
  view = params[:view].to_sym
  host = params[:host].to_sym
  interval = params[:interval].to_i
  
  graph = GraphDrawer::view.default[view] || GraphDrawer::view.machines[host][view]
  Yajl::Encoder.new.encode(graph.to_hash(host, interval))
end




