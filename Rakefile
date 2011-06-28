#!/usr/bin/env ruby
$:<< 'lib' << 'apis' << 'middlewares' << 'models'

require 'rake/clean'
require 'goliath/runner'
require 'bundler/setup'
#Bundler::GemHelper.install_tasks


task :default => [:spec]
task :test => [:spec]

begin
  require 'tasks/standalone_migrations'
  MigratorTasks.new do |t|
     # t.migrations = "db/migrations"
     # t.config = "db/config.yml"
     # t.schema = "db/schema.rb"
     # t.sub_namespace = "dbname"
     # t.env = "DB"
     # t.default_env = "development"
     # t.verbose = true
#!/usr/bin/env ruby
     # t.log_level = Logger::ERROR
  end
rescue LoadError => e
  puts "gem install standalone_migrations to get db:migrate:* tasks! (Error: #{e})"
end

  
