class User < ActiveRecord::Base
  set_primary_key :mongo_id
  
  attr_accessible :mongo_id, :first_name, :last_name, :username, :avatar_host, :avatar
  
  validates_presence_of :mongo_id
  validates_uniqueness_of :mongo_id, :username

  def as_json(options)
    options ||= {}
    hash = super(options.merge({:include => :thumbnails}))
    if thumbs = hash.delete(:thumbnails)
      thumbs.each {|t| hash.merge!({t['name']=>t['filename']})}
    end
    hash
  end
  
end
