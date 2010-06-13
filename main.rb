#!/usr/bin/env ruby

__DIR__ = File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'bundler'
Bundler.require


# temporary hack to use rrdcahced unix socket
class Errand
  def fetch(opts={})
    start  = (opts[:start] || Time.now.to_i - 3600).to_s
    finish = (opts[:finish] || Time.now.to_i).to_s
    function = opts[:function] ? opts[:function].to_s.upcase : "AVERAGE"

    args = [@filename, "--start", start, "--end", finish, function, "--daemon", "unix:/tmp/rrdcached.sock"]

    data = @backend.fetch(*args)
    start  = data[0]
    finish = data[1]
    labels = data[2]
    values = data[3]
    points = {}

    # compose a saner representation of the data
    labels.each_with_index do |label, index|
      points[label] = []
      values.each do |tuple|
        value = tuple[index].nan? ? nil : tuple[index]
        points[label] << value
      end
    end

    {:start => start, :finish => finish, :data => points}
  end
end

require File.expand_path('../lib/graph_series/base', __FILE__)
require File.expand_path('../lib/graph_series/line', __FILE__)
require File.expand_path('../lib/graph_series/bar', __FILE__)
require File.join(__DIR__, 'lib/graph')
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
  @hosts = RRDFaces::view.machines.keys
  haml :index
end

get '/*' do
  # check if a template exist
  template_path = File.join(__DIR__, '/views', "#{params[:splat][0]}.haml")
  puts "PATH: #{template_path}"
  pass unless File.exist?(template_path)
  
  haml "#{params[:splat][0]}".to_sym
end

get '/:host' do 
  if RRDFaces::view.machines[params[:host].to_sym]
    @hosts = RRDFaces::view.machines.keys
  
    @graphs = RRDFaces::view.default.values
    @graphs << RRDFaces::view.machines[params[:host].to_sym].values
    @graphs.flatten!
  
    haml :index
  end
end

get '/data/:host/:view' do
  content_type :json
  
  view = params[:view].to_sym
  host = params[:host].to_sym
  interval = params[:interval].to_i
  index = params[:index].to_i
  
  graph = RRDFaces::view.default[view] || RRDFaces::view.machines[host][view]
  Yajl::Encoder.new.encode(graph.to_hash(host, interval, index))
end

