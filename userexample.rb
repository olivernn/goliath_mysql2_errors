#!/usr/bin/env ruby
$:<< 'lib' << 'app' << 'config'

require 'bundler/setup'
require 'goliath/runner'
require 'goliath'
require 'yajl/json_gem'
require 'foodtree'

#require all models
require 'active_record'
ActiveRecord::Base.include_root_in_json = false
ActiveRecord::Base.establish_connection(:adapter  => 'em_mysql2',
                                      :database => 'userexample_development',
                                      :username => 'root',
                                      :password => '',
                                      :host     => 'localhost',
                                      :pool    => 20,
                                      :wait_timeout => 0.9
                                      )

%w{apis models middlewares workers}.each do |dir|
  $LOAD_PATH.unshift File.dirname(__FILE__) + "/app/" + dir
  
  Dir[File.dirname(__FILE__) + '/app/' + dir + '/*.rb'].each do |file| 
    require File.basename(file, File.extname(file))
  end
end

# require 'rack/fiber_pool'
# require 'active_record/connection_adapters/abstract_adapter'



# ---------- Authorization Middleware ----------------------

# Example demonstrating how to use a custom rack builder with the
# Goliath server and mixing Goliath APIs with normal Rack end points.
#
# Note, that the same routing behavior is supported by Goliath, loost at
# the rack_routes.rb example to see how to define custom routes.
class Userexample < Goliath::API
  use Goliath::Rack::Reloader if ENV['RACK_ENV'] == 'development'
  use Goliath::Rack::Tracer, 'X-Tracer'
  use Goliath::Rack::Params             # parse & merge query and body parameter

  #fiber pool...
  # use Rack::FiberPool do |fp|
    # ActiveRecord::ConnectionAdapters.register_fiber_pool(fp)
  # end

  # use ActiveRecord::ConnectionAdapters::ConnectionManagement

  # catch the root route and return a 404
  map "/" do
    #run Proc.new { |env| [404, {"Content-Type" => "application/json"}, JSON.generate({:return => "invalid action"})]  }
    run DefaultAPI.new
  end
    
  map "/users/:id" do
    run Users.new
  end
  
  map "/users" do
    run Users.new
  end
end

class DefaultAPI < Foodtree::API  
    
  def response(env)
    resp = route_request
  end
    
  private 

  def index
    env.logger.debug "---------------------------  GET Default  ---------------------------------"
    error_on(NotFoundError, "no resource for root url")
  end
  
  def show
    error_on(NotFoundError, "this is not a valid resource")
  end
  
end
