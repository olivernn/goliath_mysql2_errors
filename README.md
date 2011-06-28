The mysql2 bug
----------------

We keep running into this bug with mysql2 and ActiveRecord. It happens with some consistency even under a situation of low concurrency. With this simple example it seems like I have to crank up the threads a bit to get the error to show - but it will show!

Installation
----------------
    git clone git@github.com:Foodtree/goliath_mysql2_errors.git

    cd goliath_mysql2_errors

    bundle install

Standalone migrations are included so you should be able to do this to get the db set up.

    rake db:create
    rake db:migrate

start up the server
  
    ruby userexample.rb -sv

run the full_test.rb in a different console window
note: the params are loops and threads. This example will create 20 threads that create a user and change the username 20 times

    ./full_test.rb development 20 20

example error:
-----------------
    [72366:DEBUG] 2011-06-28 16:23:22 :: Users ROUTING - 
    [72366:INFO] 2011-06-28 16:23:22 :: Users route_request:   attempting to call update action
    [72366:DEBUG] 2011-06-28 16:23:22 :: Users API:   ---- update
    [72366:DEBUG] 2011-06-28 16:23:22 :: Users API verify_put_params:  put params are {"user"=>{"username"=>"radix27657"}, :id=>"9386311200", "id"=>"9386311200"}
    [72366:DEBUG] 2011-06-28 16:23:22 :: Users API verify_put_params:  Params are: {"username"=>"radix27657", "id"=>"9386311200"} and of type Hash
    [72366:DEBUG] 2011-06-28 16:23:22 :: Users API do_put:   creating user with params {"username"=>"radix27657", "id"=>"9386311200"}
    [72366:ERROR] 2011-06-28 16:23:22 :: Mysql2::Error: This connection is still waiting for a result, try again once you have the result: SELECT  `users`.* FROM `users` WHERE `users`.`mongo_id` = '9386311200' LIMIT 1
    [72366:ERROR] 2011-06-28 16:23:22 :: /Users/chrisd/.rvm/gems/ruby-1.9.2-p180@userexample/gems/activerecord-3.0.9/lib/active_record/connection_adapters/abstract_adapter.rb:207:in `rescue in log'
    /Users/chrisd/.rvm/gems/ruby-1.9.2-p180@userexample/gems/activerecord-3.0.9/lib/active_record/connection_adapters/abstract_adapter.rb:199:in `log'
    /Users/chrisd/.rvm/gems/ruby-1.9.2-p180@userexample/gems/mysql2-0.2.11/lib/active_record/connection_adapters/mysql2_adapter.rb:265:in `execute'
    /Users/chrisd/.rvm/gems/ruby-1.9.2-p180@userexample/gems/mysql2-0.2.11/lib/active_record/connection_adapters/mysql2_adapter.rb:586:in `select'
    /Users/chrisd/.rvm/gems/ruby-1.9.2-p180@userexample/gems/activerecord-3.0.9/lib/active_record/connection_adapters/abstract/database_statements.rb:7:in `select_all'

