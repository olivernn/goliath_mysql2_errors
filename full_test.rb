#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'fileutils'

class FullTest
  
  def initialize(args)
    @env = args[0] || 'development'
    @repeat = args[1] || 1
    @threads = args[2] || 0
    @username = args[3] || "billybobD#{rand(99999)*rand(999)}"
    @user_password = args[4] || 'testing'
    @user_email = args[5] || "#{@username}@foodtree.com"

    @repeat = @repeat.to_i
    @threads = @threads.to_i
    
    @verbose = false
    case @env
    when 'development'
      @auth_server = 'http://localhost:3000'
      @api_server = 'http://localhost:9000'
    when 'production'
      @auth_server = 'http://prod.authserver.net'
      @api_server = 'http://prod.apiserver.net' #removed real server values
    end
  end

  #make sure log dir exists
  def ensure_log_dir
    puts "creating log folder #{File.dirname(__FILE__)+'log/test/curl'}"  if @verbose
    FileUtils.mkdir_p File.dirname(__FILE__)+'/log/test/curl'
  end

  def create_user(user_id, username, log_index = 1)
    req = <<-request
          curl --trace-ascii log/test/curl/#{log_index}-post_user_curl.trace \
          --url #{@api_server}/users \
          -X POST \
          -H "Expect: "\
          -F "user[id]=#{user_id}" \
          -F "user[first_name]=Joe" \
          -F "user[last_name]=Tester" \
          -F "user[username]=#{username}"
        request
        #-F "user[avatar_url]=#{s3_info['post_to']+s3_info['key']}"
    puts req
    resp = `#{req}`
  end
  
  def change_username(user_id, username, log_index = 1)
    req = <<-request
      curl --trace-ascii log/test/curl/#{log_index}-change_username.trace \
      -X PUT \
      --url #{@api_server}/users/#{user_id} \
      -H 'Expect:'\
      -F "user[username]=#{username}"
    request
    puts req
    resp = `#{req}`
  end


  def full_test(id=1)
    @tracers[id] = []
    #do the auth outside of the test so it doesn't add a external meter
    user_id = rand(9000)*rand(9000)*rand(9000)
    trace(id, "create user (#{user_id})") {create_user(user_id, "radix#{user_id}", id)}
    @repeat.times do |i|
      trace(id, 'change username') {change_username(user_id, "radix#{rand(999999)}", "#{id}+#{i}")}
      @tracers[id] << "--" #just separate the loops
    end
    
  end
  
  def trace(id, name)
    t = Time.now
    r = yield
    @tracers[id] << "#{id}-#{@tracers[id].length} :: #{name} done in #{Time.now - t}"
    r #don't return the tracers, but instead the result of the block
  end
  
  def dump_tracers
    @tracers.each do |k, v|
      puts "Tracers for thread #{k}\n--------------------------------------------"
      v.each do |results|
        puts results
      end
    end
  end
  
  
  def run
    ensure_log_dir
    @tracers = {}
    running_threads = []
    if @threads > 0
      @threads.times do |t|
        Thread.new do
          running_threads << Thread.current.object_id
          full_test(t)
          running_threads.delete(Thread.current.object_id)
        end
      end
      
      #wait for the threads to complete
      sleep(2)
      while running_threads.length > 0
        puts "#{running_threads.length} still running"
        sleep(3)
      end
      puts "all threads have completed"
    else
      puts "no threading required"
      full_test
    end
    
    dump_tracers
  end
  
end

ft = FullTest.new(ARGV)
ft.run

