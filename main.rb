#!/usr/bin/env ruby

__DIR__ = File.expand_path(File.dirname(__FILE__))

begin
  # Require the preresolved locked set of gems.
  require File.expand_path('.bundle/environment', __DIR__)
rescue LoadError
  # Fallback on doing the resolve at runtime.
  require "bundler"
  Bundler.setup
end

# sinatra have to be required there or else
# "ruby visage.rb" does not work to run the app
require 'sinatra'

Bundler.require

require File.join(__DIR__, 'lib/config_loader')
require File.join(__DIR__, 'config/config')

set :public, __DIR__ + '/public'
set :views,  __DIR__ + '/views'

template :layout do 
  File.read(File.join(__DIR__, 'views/layout.haml'))
end

use Rack::Auth::Basic do |username, password|
  [username, password] == ['admin', 'admin']
end


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




