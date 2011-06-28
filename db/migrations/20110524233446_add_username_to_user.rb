class AddUsernameToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :username, :string
  end

  def self.down
    remove_column :users, :username
    raise ActiveRecord::IrreversibleMigration
  end
end