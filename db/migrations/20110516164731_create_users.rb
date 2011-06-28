class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users, {:id => false} do |t|
      t.string :mongo_id
      t.string :first_name
      t.string :last_name
    end
    
    execute "ALTER TABLE users ADD PRIMARY KEY (mongo_id);"
  end

  def self.down
    drop_table :users
  end
end
