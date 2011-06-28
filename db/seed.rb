#!/usr/bin/env ruby
## RUN THIS VIA rake db:seed

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../app/models/'

require 'active_record'

env = ENV['DB'] || 'development'

#so much for DRY - need to figure out how to call the config from other places!
#set up mysql coonection for active record models
#TODO: we need to integrate mysql db configuration (db/config.yml) into goliath configg
case env
  when 'development' then ActiveRecord::Base.establish_connection(:adapter  => 'em_mysql2',
                                        :database => 'slapichop_development',
                                        :username => 'root',
                                        :password => '',
                                        :host     => 'localhost')
                                      
  when 'production' then   ActiveRecord::Base.establish_connection(:adapter  => 'em_mysql2',
                                       :database => 'slapichop_production',
                                       :username => 'foodtree',
                                       :password => 'th1s1sth3waythatF00dTr33Playz',
                                       :host     => 'ec2-50-19-103-87.compute-1.amazonaws.com',
                                       :port     => 3114)
  
   when 'test' then ActiveRecord::Base.establish_connection(:adapter  => 'em_mysql2',
                                         :database => 'slapichop_test',
                                         :username => 'root',
                                         :password => '',
                                         :host     => 'localhost')
                                                                           
end

%w{models}.each do |dir|
  
  Dir[File.dirname(__FILE__) + '/../app/' + dir + '/*.rb'].each do |file| 
    require File.basename(file, File.extname(file))
  end

end




#don't need to do this anymore - use rake db:load_sources  
# Source.delete_all
# ActiveRecord::Base.connection.execute('ALTER TABLE sources AUTO_INCREMENT = 1')
# Source.create!(:name=>'Old Macdonald Farm')
# Source.create!(:name=>'Ye Olde Farmers Market')
# Source.create!(:name=>'Le Gusto Mojo Restaurant')
# Source.create!(:name=>'Big Pig Slaughterhouse')
# Source.create!(:name=>'Fresh Fragrant Greens')

# build map_points table from sources table
ActiveRecord::Base.connection.execute "DELETE from map_points where mappable_type = 'Source'"
ActiveRecord::Base.connection.execute "INSERT INTO map_points( name, lat, lng, mappable_id, mappable_type) SELECT name, latitude, longitude, id, 'Source' as mappable_type FROM sources"



# Loading Source Types and Food Types 
def create_children(parent, children, model_class)
  puts "creating children of #{parent.name}\n----------------"
  children.each do |k, v|
    puts "Creating #{model_class.name} for #{k}"
    parent.children.create!(:name => k, :uuid => v['uuid'])
    if v['children']
      new_parent = model_class.find_by_name(k)
      create_children(new_parent, v['children'], model_class)
    end
  end
  
  puts "No more children left\n--------------------"
end

['SourceType', 'FoodType'].each do |model_name|
  model_class = Kernel.const_get(model_name)
  model_table_name = (model_name.gsub(/[A-Z][a-z]*/){|s| "_"+s.downcase} + "s")[1..-1]
  puts model_table_name
  
  puts "deleteing all #{model_name} reords from the DB"
  model_class.delete_all
  
  ActiveRecord::Base.connection.execute("ALTER TABLE #{model_table_name} AUTO_INCREMENT = 1")
  
  puts "Loading #{model_name} seed data from the YAML file"
  file_name = (model_table_name + ".yml")
  data = YAML.load_file(File.dirname(__FILE__) + "/../db/migrations/data/#{file_name}")
  
  data.each do |k, v|
    puts "Creating source type for #{k}"
    
    parent = model_class.find_or_create_by_name(:name => k, :uuid => v['uuid'])
    if v['children']
      create_children(parent, v['children'], model_class)
  
    end
  end

end

# DUMP In the dummy photos from S3 as stubs for testing against
ActiveRecord::Base.connection.execute('ALTER TABLE photos AUTO_INCREMENT = 1')
ActiveRecord::Base.connection.execute( "DELETE from photos")
ActiveRecord::Base.connection.execute( <<-SQL
        INSERT INTO `photos` (`id`, `user_mongo_id`, `s3_key`, `created_at`, `updated_at`,`host_url`, `image_full`) VALUES
        (22, '4dd4c534ff75850001000001', 'uploaded_images/20110519173251/image_20.jpg', '2011-05-19 17:32:53', '2011-05-19 17:32:53', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173251/',     'image_20_full.jpg'),
        (10, '4dd4c534ff75850001000001', 'uploaded_images/20110519173103/image_08.jpg', '2011-05-19 17:31:05', '2011-05-19 17:31:05', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173103/',     'image_08_full.jpg'),
        (6, '4dd4c534ff75850001000001', 'uploaded_images/20110519173025/image_04.jpg', '2011-05-19 17:30:27', '2011-05-19 17:30:27', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173025/',     'image_04_full.jpg'),
        (18, '4dd4c534ff75850001000001', 'uploaded_images/20110519173210/image_16.jpg', '2011-05-19 17:32:17', '2011-05-19 17:32:17', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173210/',     'image_16_full.jpg'),
        (17, '4dd4c534ff75850001000001', 'uploaded_images/20110519173202/image_15.jpg', '2011-05-19 17:32:05', '2011-05-19 17:32:05', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173202/',     'image_15_full.jpg'),
        (5, '4dd4c534ff75850001000001', 'uploaded_images/20110519173017/image_03.jpg', '2011-05-19 17:30:19', '2011-05-19 17:30:19', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173017/',     'image_03_full.jpg'),
        (12, '4dd4c534ff75850001000001', 'uploaded_images/20110519173120/image_10.jpg', '2011-05-19 17:31:23', '2011-05-19 17:31:23', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173120/',     'image_10_full.jpg'),
        (20, '4dd4c534ff75850001000001', 'uploaded_images/20110519173231/image_18.jpg', '2011-05-19 17:32:37', '2011-05-19 17:32:37', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173231/',     'image_18_full.jpg'),
        (8, '4dd4c534ff75850001000001', 'uploaded_images/20110519173042/image_06.jpg', '2011-05-19 17:30:44', '2011-05-19 17:30:44', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173042/',     'image_06_full.jpg'),
        (19, '4dd4c534ff75850001000001', 'uploaded_images/20110519173221/image_17.jpg', '2011-05-19 17:32:27', '2011-05-19 17:32:27', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173221/',     'image_17_full.jpg'),
        (7, '4dd4c534ff75850001000001', 'uploaded_images/20110519173032/image_05.jpg', '2011-05-19 17:30:34', '2011-05-19 17:30:34', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173032/',     'image_05_full.jpg'),
        (2, '4dd4c534ff75850001000001', 'uploaded_images/20110519074734/yummyfood01.jpg', '2011-05-19 07:47:35', '2011-05-19 07:47:35', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519074734/',     'yummyfood01_full.jpg'),
        (14, '4dd4c534ff75850001000001', 'uploaded_images/20110519173137/image_12.jpg', '2011-05-19 17:31:39', '2011-05-19 17:31:39', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173137/',     'image_12_full.jpg'),
        (13, '4dd4c534ff75850001000001', 'uploaded_images/20110519173130/image_11.jpg', '2011-05-19 17:31:32', '2011-05-19 17:31:32', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173130/',     'image_11_full.jpg'),
        (1, '4dd4c534ff75850001000001', 'uploaded_images/20110519004542/yummyfood01.jpg', '2011-05-19 00:45:44', '2011-05-19 00:45:44', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519004542/',     'yummyfood01_full.jpg'),
        (9, '4dd4c534ff75850001000001', 'uploaded_images/20110519173052/image_07.jpg', '2011-05-19 17:30:54', '2011-05-19 17:30:54', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173052/',     'image_07_full.jpg'),
        (21, '4dd4c534ff75850001000001', 'uploaded_images/20110519173241/image_19.jpg', '2011-05-19 17:32:44', '2011-05-19 17:32:44', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173241/',     'image_19_full.jpg'),
        (16, '4dd4c534ff75850001000001', 'uploaded_images/20110519173154/image_14.jpg', '2011-05-19 17:31:56', '2011-05-19 17:31:56', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173154/',     'image_14_full.jpg'),
        (4, '4dd4c534ff75850001000001', 'uploaded_images/20110519172953/image_02.jpg', '2011-05-19 17:29:56', '2011-05-19 17:29:56', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519172953/',     'image_02_full.jpg'),
        (15, '4dd4c534ff75850001000001', 'uploaded_images/20110519173145/image_13.jpg', '2011-05-19 17:31:47', '2011-05-19 17:31:47', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173145/',     'image_13_full.jpg'),
        (3, '4dd4c534ff75850001000001', 'uploaded_images/20110519171533/image_01.jpg', '2011-05-19 17:15:36', '2011-05-19 17:15:36', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519171533/',     'image_01_full.jpg'),
        (11, '4dd4c534ff75850001000001', 'uploaded_images/20110519173112/image_09.jpg', '2011-05-19 17:31:14', '2011-05-19 17:31:14', 'http://foodtreeimg.s3.amazonaws.com/uploaded_images/20110519173112/',     'image_09_full.jpg')
SQL
)
ActiveRecord::Base.connection.execute( "DELETE from photos_sources")
ActiveRecord::Base.connection.execute( <<-SQL
            INSERT INTO `photos_sources` (`id`, `photo_id`, `source_id`, `created_at`, `updated_at`) VALUES
            (7, 7, 6, '2011-05-19 17:30:35', '2011-05-19 17:30:35'),
            (19, 19, 6, '2011-05-19 17:32:27', '2011-05-19 17:32:27'),
            (15, 15, 6, '2011-05-19 17:31:47', '2011-05-19 17:31:47'),
            (3, 3, 6, '2011-05-19 17:15:37', '2011-05-19 17:15:37'),
            (14, 14, 6, '2011-05-19 17:31:39', '2011-05-19 17:31:39'),
            (2, 2, 6, '2011-05-19 07:47:36', '2011-05-19 07:47:36'),
            (21, 21, 6, '2011-05-19 17:32:44', '2011-05-19 17:32:44'),
            (9, 9, 6, '2011-05-19 17:30:54', '2011-05-19 17:30:54'),
            (5, 5, 6, '2011-05-19 17:30:19', '2011-05-19 17:30:19'),
            (17, 17, 6, '2011-05-19 17:32:05', '2011-05-19 17:32:05'),
            (16, 16, 6, '2011-05-19 17:31:56', '2011-05-19 17:31:56'),
            (4, 4, 6, '2011-05-19 17:29:57', '2011-05-19 17:29:57'),
            (11, 11, 6, '2011-05-19 17:31:14', '2011-05-19 17:31:14'),
            (10, 10, 6, '2011-05-19 17:31:05', '2011-05-19 17:31:05'),
            (22, 22, 6, '2011-05-19 17:32:53', '2011-05-19 17:32:53'),
            (18, 18, 6, '2011-05-19 17:32:18', '2011-05-19 17:32:18'),
            (6, 6, 6, '2011-05-19 17:30:27', '2011-05-19 17:30:27'),
            (13, 13, 6, '2011-05-19 17:31:32', '2011-05-19 17:31:32'),
            (1, 1, 6, '2011-05-19 00:45:45', '2011-05-19 00:45:45'),
            (12, 12, 6, '2011-05-19 17:31:23', '2011-05-19 17:31:23'),
            (8, 8, 6, '2011-05-19 17:30:44', '2011-05-19 17:30:44'),
            (20, 20, 6, '2011-05-19 17:32:37', '2011-05-19 17:32:37')
SQL
)

City.create!(:name=>'Vancouver', :lat=> 49.1, :lng => -123.1)

